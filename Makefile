THIS_FILE := $(lastword $(MAKEFILE_LIST))
.PHONY: help build up start down destroy stop restart logs logs-api ps login-timescale login-api db-shell auth apply plan destroy

include .env

help:
	make -pRrq  -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

build:
	docker-compose -f docker-compose.prod.yml build $(c)

up:
	docker-compose -f docker-compose.prod.yml up -d $(c)

push:
	docker-compose -f docker-compose.prod.yml push $(c)

down:
	docker-compose -f docker-compose.prod.yml down $(c)

logs:
	docker-compose -f docker-compose.prod.yml logs -f $(c)

ps:
	docker-compose -f docker-compose.prod.yml ps $(c)

auth:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

apply:
	terraform apply

plan:
	terraform plan

destroy:
	terraform destroy
