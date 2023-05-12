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
- example:
    - <img src="http://localhost:8000/media/dalle_ai_surrealist_search.png" style="width:100%; height:auto;"/>
    - #TODO: test local docker and fargate prod deploys

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

## media and static
- media via reverse proxy
- static handled via whitenoise
   - TODO: css not loading /admin/, staticfiles issue somewhere in prod...whitenoise blame?

## FIX ME FIRST
 - /admin/ in prod, throwing 404 on UN/PW login, it tries to load ImagePIL for Author and not found.  Did I delete it?

## cli tool
- api calls to dalle2
- api calls to gpt-4, including conversation storage for django static files, maybe use hte microsoft semantic kernal repo?

## conversation idea
- leverage the database model and markdown formatting for the most flexibility
- render conversations.html via a link for users to read the full exchange if they desire
- this keeps the post focused on the critical parts of the conversation
------------------------------------------------------------------------------
## TODOs
- eventually migrate to K8
- gitignore requirements.txt
- add diagrams
- improve how I am using sqllite, rds replace?
- django html template specifically for promptEngineering posts?
- review manage.py check --deploy for production readiness
