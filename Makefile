SHELL := /bin/bash

VERSION ?= $(shell head -1 version.txt)

push_registry := superhumane
pull_registry := hasura
packager_ver := 20190731
pg_dump_ver := 11#13
build_output := /build/_server_output

# startup postgres container and bash into hasura container
up: 
	docker-compose up
	# docker-compose up -d postgres
	# docker-compose run hasura scripts/dev.sh graphql-engine

bash:
	docker exec -it graphql-engine bash

# stop postgres and hasura containers
stop:
	docker-compose stop

# DESTROY postgres DB and delete build files
destroy:
	docker-compose stop
	sudo rm -rf db/postres
	sudo rm -rf console/node_modules
	sudo rm -rf server/dist-newstyle
	sudo rm -f server/cabal.project.local

db_connect:
	docker exec -it hasura-db psql postgres://hasura:hasura@postgres:5432/postgres

# hasura container needs to be running before executing
compile:
	docker exec -it graphql-engine sh -c "cd console && npm ci && npm run server-build && cd ../server && rm -f cabal.project.local && ln -s cabal.project.dev cabal.project.local && cabal new-update && cabal new-build"

build:
	docker exec -it graphql-engine sh -c "cd server && cabal new-build"

run:
	docker exec -it graphql-engine sh -c "cd server && cabal new-run -- exe:graphql-engine \
		--database-url='postgres://hasura:hasura@postgres:5432/postgres' \
		serve --enable-console --console-assets-dir=../console/static/dist"

# assumes this is built in circleci
ci-build:
	docker exec -it graphql-engine sh -c "cd server && make ci-build && \
		../scripts/get-version.sh > $(build_output)/version.txt"

# assumes this is built in circleci
ci-image:
	docker rm -f dummy && \
	docker exec -it graphql-engine sh -c "cd server && \
		head -1 $(build_output)/version.txt && \
		mkdir -p packaging/build/rootfs"
	docker create -v /root/ --name dummy alpine:3.4 /bin/true
	docker cp '.$(build_output)/graphql-engine' dummy:/root/
	docker run --rm --volumes-from dummy '$(pull_registry)/graphql-engine-packager:$(packager_ver)' /build.sh graphql-engine | tar -x -C server/packaging/build/rootfs
	docker exec -it graphql-engine sh -c "cd server && \
		strip --strip-unneeded packaging/build/rootfs/bin/graphql-engine && \
		cp '/usr/lib/postgresql/$(pg_dump_ver)/bin/pg_dump' packaging/build/rootfs/bin/pg_dump && \
		upx packaging/build/rootfs/bin/graphql-engine"
	docker build -t '$(push_registry)/graphql-engine:$(VERSION)' server/packaging/build/


.PHONY: up stop destroy	db_connect compile build run
