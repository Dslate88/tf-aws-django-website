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
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent


ALLOWED_HOSTS = os.environ["ALLOWED_HOSTS"].split(" ")
DEBUG = os.environ["DEBUG"]
DEFAULT_AUTO_FIELD = os.environ["DEFAULT_AUTO_FIELD"]
LANGUAGE_CODE = os.environ["LANGUAGE_CODE"]
ROOT_URLCONF = os.environ["ROOT_URLCONF"]
SECRET_KEY = os.environ["SECRET_KEY"]
STATIC_URL = os.environ["STATIC_URL"]
TIME_ZONE = os.environ["TIME_ZONE"]
USE_I18N = os.environ["USE_I18N"]
USE_TZ = os.environ["USE_TZ"]
WSGI_APPLICATION = os.environ["WSGI_APPLICATION"]
LOGIN_REDIRECT_URL = os.environ["LOGIN_REDIRECT_URL"]
CRISPY_TEMPLATE_PACK = os.environ["CRISPY_TEMPLATE_PACK"]
MEDIA_ROOT = os.path.join(BASE_DIR, os.environ["MEDIA_ROOT"])
MEDIA_URL = os.environ["MEDIA_URL"]


INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "blog.apps.BlogConfig",
    "users.apps.UsersConfig",
    "crispy_forms",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
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

STATICFILES_DIRS = [
    BASE_DIR / "static/",
]
