"""
base URL Configuration

urls:
    - admin: provided admin capability
    - blog:  custom blog application
"""
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("", include("blog.urls")),  # temporary
    path("admin/", admin.site.urls),
    path("blog/", include("blog.urls")),
]
