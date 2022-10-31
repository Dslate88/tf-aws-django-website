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
import configparser
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent


config = configparser.ConfigParser()
config.read(BASE_DIR / "config.ini")


ALLOWED_HOSTS = []
DEBUG = config["LOCAL"]["DEBUG"]
DEFAULT_AUTO_FIELD = config["LOCAL"]["DEFAULT_AUTO_FIELD"]
LANGUAGE_CODE = config["LOCAL"]["LANGUAGE_CODE"]
ROOT_URLCONF = config["LOCAL"]["ROOT_URLCONF"]
SECRET_KEY = config["LOCAL"]["SECRET_KEY"]
STATIC_URL = config["LOCAL"]["STATIC_URL"]
TIME_ZONE = config["LOCAL"]["TIME_ZONE"]
USE_I18N = config["LOCAL"]["USE_I18N"]
USE_TZ = config["LOCAL"]["USE_TZ"]
WSGI_APPLICATION = config["LOCAL"]["WSGI_APPLICATION"]
LOGIN_REDIRECT_URL = config["LOCAL"]["LOGIN_REDIRECT_URL"]
CRISPY_TEMPLATE_PACK = config["LOCAL"]["CRISPY_TEMPLATE_PACK"]
MEDIA_ROOT = os.path.join(BASE_DIR, config["LOCAL"]["MEDIA_ROOT"])
MEDIA_URL = config["LOCAL"]["MEDIA_URL"]


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
