#!/bin/bash

# git pull origin master
python3 base/manage.py makemigrations
python3 base/manage.py migrate
python3 base/manage.py runserver 0.0.0.0:8000

