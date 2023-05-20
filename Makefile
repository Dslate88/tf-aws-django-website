# THIS_FILE := $(lastword $(MAKEFILE_LIST))
# .PHONY: help build up start down destroy stop restart logs logs-api ps login-timescale login-api db-shell auth apply plan destroy prune

include .env

# help:
# 	make -pRrq  -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

build:
	#TODO: just store me in nginx/ and rm from django/
	cp -r django/media/ nginx/media/
	cp -r django/static/ nginx/static/

ifeq ($(env),prod)
	cd nginx && ./generate_nginx_conf.sh 127.0.0.1:8000
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache $(c)
else
	cd nginx && ./generate_nginx_conf.sh django:8000
	docker-compose -f docker-compose.yml build --no-cache $(c)
endif

# TODO: add a grep for nginx prod upstream server setting, exit 1 if its not set for prod env
up:
ifeq ($(env),prod)
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d $(c)
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml exec django python manage.py collectstatic --no-input
else
	docker-compose -f docker-compose.yml up -d $(c)
	docker-compose -f docker-compose.yml exec django python manage.py collectstatic --no-input
endif

push:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml push $(c)

down:
ifeq ($(env),prod)
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml down $(c)
else
	docker-compose -f docker-compose.yml down $(c)
endif


logs:
ifeq ($(env),prod)
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f $(c)
else
	docker-compose -f docker-compose.yml logs -f $(c)
endif

ps:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps $(c)

prune:
	docker system prune -a

auth:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# TODO: rm me soon
get_db:
	# backup data locally
	cp django/db.sqlite3 "backups/$(shell date +"%Y-%m-%-d-%H-%M-%S").db.sqlite3"

    # extract db from container
	docker cp $(shell docker ps -aqf "name=tf-aws-django-website_django"):home/app/db.sqlite3 django/db.sqlite3

requirements:
	pipenv run pip freeze > django/requirements.txt

debug:
ifeq ($(env),prod)
	make down env=prod
	make build env=prod
	make up env=prod
	make get_db
else
	make down
	make build
	make up
	make logs
endif

server:
	cd django && python manage.py runserver
