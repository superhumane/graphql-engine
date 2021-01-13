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

.PHONY: up stop destroy	db_connect compile build run
