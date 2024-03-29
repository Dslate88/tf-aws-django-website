"""
Django settings for base project.

For more information on this file, see
- https://docs.djangoproject.com/en/4.1/topics/settings/

For the full list of settings and their values, see
- https://docs.djangoproject.com/en/4.1/ref/settings/

Quick-start development settings - unsuitable for production
- See https://docs.djangoproject.com/en/4.1/howto/deployment/checklist/
"""

import os
import environ
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

if os.environ["DEPLOY_ENV"] == "prod":
    environ.Env.read_env(os.path.join(BASE_DIR, ".env.webapp.prod"))
else:
    environ.Env.read_env(os.path.join(BASE_DIR, ".env.webapp"))

env = environ.Env(
    # set casting, default value
    DEBUG=(bool, False),
    CSRF_COOKIE_SECURE=(bool, True),
    USE_I18N=(bool, True),
    USE_TZ=(bool, True),
    SECURE_HSTS_INCLUDE_SUBDOMAINS=(bool, True),
    SESSION_COOKIE_SECURE=(bool, True),
    SECURE_SSL_REDIRECT=(bool, True),
)

ALLOWED_HOSTS = env("ALLOWED_HOSTS").split(" ")
DEBUG = env("DEBUG")
DEFAULT_AUTO_FIELD = env("DEFAULT_AUTO_FIELD")
LANGUAGE_CODE = env("LANGUAGE_CODE")
ROOT_URLCONF = env("ROOT_URLCONF")
SECRET_KEY = env("SECRET_KEY")
STATIC_URL = env("STATIC_URL")
STATIC_ROOT = os.path.join(BASE_DIR, env("STATIC_ROOT"))
TIME_ZONE = env("TIME_ZONE")
USE_I18N = env("USE_I18N")
USE_TZ = env("USE_TZ")
WSGI_APPLICATION = env("WSGI_APPLICATION")
LOGIN_REDIRECT_URL = env("LOGIN_REDIRECT_URL")
CRISPY_TEMPLATE_PACK = env("CRISPY_TEMPLATE_PACK")
MEDIA_ROOT = os.path.join(BASE_DIR, env("MEDIA_ROOT"))
MEDIA_URL = env("MEDIA_URL")
SECURE_HSTS_SECONDS = env("SECURE_HSTS_SECONDS")
SECURE_HSTS_INCLUDE_SUBDOMAINS = env("SECURE_HSTS_INCLUDE_SUBDOMAINS")
CSRF_COOKIE_SECURE = env("CSRF_COOKIE_SECURE")
SESSION_COOKIE_SECURE=env("SESSION_COOKIE_SECURE")

CRISPY_TEMPLATE_PACK = "bootstrap4"

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "whitenoise.runserver_nostatic",
    "django.contrib.staticfiles",
    "blog.apps.BlogConfig",
    "users.apps.UsersConfig",
    "crispy_forms",
    "crispy_bootstrap4",
    "markdownx",
]

MIDDLEWARE = [
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "base.middleware.HealthCheckMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [os.path.join(BASE_DIR, "templates")],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]
