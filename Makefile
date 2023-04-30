THIS_FILE := $(lastword $(MAKEFILE_LIST))
.PHONY: help build up start down destroy stop restart logs logs-api ps login-timescale login-api db-shell auth apply plan destroy prune

include .env

help:
	make -pRrq  -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

build:
	cp -r django/media/ nginx/prod/media/
	cp -r django/static/ nginx/prod/static/
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache$(c)

# TODO: add a grep for nginx prod upstream server setting, exit 1 if its not set for prod env
up:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d $(c)
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml exec django python manage.py collectstatic --no-input --clear

push:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml push $(c)

down:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml down $(c)

logs:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f $(c)

ps:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps $(c)

prune:
	docker system prune -a

auth:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

dev_build:
	docker-compose -f docker-compose.yml build $(c)

dev_up:
	docker-compose -f docker-compose.yml up -d $(c)

dev_down:
	docker-compose -f docker-compose.yml down $(c)

get_db:
	# backup data locally
	cp django/db.sqlite3 "backups/$(shell date +"%Y-%m-%-d-%H-%M-%S").db.sqlite3"

    # extract db from container
	docker cp $(shell docker ps -aqf "name=tf-aws-django-website_django"):home/app/db.sqlite3 django/db.sqlite3

requirements:
	pipenv run pip freeze > django/requirements.txt
