"""
base URL Configuration

urls:
    - admin: provided admin capability
    - blog:  custom blog application
    - users: custom blog application
"""
from django.contrib import admin
from django.contrib.auth import views as auth_views
from django.urls import path, include

from users import views as v


urlpatterns = [
    path("", include("blog.urls")),  # temporary
    path("admin/", admin.site.urls),
    path("blog/", include("blog.urls")),
    path(
        "register/",
        v.UserRegister.as_view(template_name="users/register.html"),
        name="user-register",
    ),
    path(
        "login/",
        auth_views.LoginView.as_view(template_name="users/login.html"),
        name="user-login",
    ),
    path(
        "logout/",
        auth_views.LogoutView.as_view(template_name="users/logout.html"),
        name="user-logout",
    ),
]
