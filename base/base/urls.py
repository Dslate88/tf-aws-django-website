"""
base URL Configuration

urls:
    - admin:    provided admin capability
    - blog:     blog application [/home, /about]
    - register: users app new user account creation
    - login:    users app user sign in
    - logout:   users app user sign out
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.contrib.auth import views as auth_views
from django.urls import path, include

from users import views as v
from blog.views import PostDetailView, PostCreateView, PostUpdateView


urlpatterns = [
    path("", include("blog.urls")),  # temporary
    path("admin/", admin.site.urls),
    path("blog/", include("blog.urls")),
    path(
        "profile/",
        v.UserProfileView.as_view(template_name="users/profile.html"),
        name="user-profile",
    ),
    path(
        "register/",
        v.UserRegisterView.as_view(template_name="users/register.html"),
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
    path("post/<int:pk>", PostDetailView.as_view(), name="post-detail"),
    path("post/add/", PostCreateView.as_view(), name="post-create"),
    path("post/update/", PostUpdateView.as_view(), name="post-update"),
    # django documented recommended pattern
    # if debug==True then this evaluates
    # TODO: refactor all this for S3, both local and production
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
