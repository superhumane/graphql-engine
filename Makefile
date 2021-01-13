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

# DESTROY postgres DB
destroy:
	docker-compose stop
	sudo rm -rf db/postres
	sudo rm -rf console/node_modules
	sudo rm -rf server/dist-newstyle
	sudo rm -f server/cabal.project.local

db_connect:
	docker exec -it hasura-db psql postgres://hasura:hasura@postgres:5432/postgres

# compile:
# 	cd console
# 	npm ci
# 	npm run server-build
# 	cd ../server
# 	ln -s cabal.project.dev cabal.project.local
# 	cabal new-update
# 	cabal new-build

.PHONY: up stop destroy	db_connect

# cabal new-run -- exe:graphql-engine \
#   --database-url='postgres://hasura:hasura@postgres:5432/postgres' \
#   serve --enable-console --console-assets-dir=../console/static/dist