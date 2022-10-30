from django.urls import path
from django.contrib.auth import views as auth_views

from .views import UserRegister

urlpatterns = [
    path("register/", UserRegister.as_view(), name="user-register"),
    path(
        "login/",
        auth_views.LoginView.as_view(template_name="users/login.html"),
        name="user-login",
    ),
]
