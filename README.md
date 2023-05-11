#
------------------------------------------------------------------------------
## notes to self: user-guide

## pipenv
- `pipenv shell`, run this when in root repo dir to activate env
- pipenv clean
make requirements

## ORM management:
- just do this locally until a db tier is added later (rds?)
    - python manage.py runserver
    - python manage.py makemigrations
    - python manage.py migrate

## markdown media file reference:
- example
    ![image](http://localhost:8000/media/kairos_default.jpg)

## what should deployment process be??
- local tf cli, replace with GHA later?
- container rollout via Fargate, rollback if failure auto...
- using sqllite for now, so...local compose up on macbook for article editing?
    - use `make get_db` for now...
    - TODO: improve on this...

## early posting workflow
- make server, localhost:8000, this will store media/static in django dir
    - if it looks good, make debug
    - confirm the post works with compose deploy + nginx, this matches prod as much as possible
    - make debug env=prod
    - make auth and make push
- thoughts on improvements later:
    - sooner...reduce above steps where you can
    - later...gitops this...automate it completely

------------------------------------------------------------------------------
## TODOs
- eventually migrate to K8
- add diagrams
- improve how I am using sqllite, rds replace?
- django html template specifically for promptEngineering posts?
- review manage.py check --deploy for production readiness
