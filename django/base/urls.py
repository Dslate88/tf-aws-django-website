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
from blog.views import PostDetailView, ConversationView
# TODO: make authorization checks for all routes..add/delete/update/etc...


urlpatterns = [
    path("portalToDimension/", admin.site.urls),
    path("", include("blog.urls")),  # temporary
    path("blog/", include("blog.urls")),
    path(
        "profile/",
        v.UserProfileView.as_view(template_name="users/profile.html"),
        name="user-profile",
    ),
    path("post/<int:pk>/", PostDetailView.as_view(), name="post-detail"),
    path('post/<int:pk>/conversation/', ConversationView.as_view(), name='post-conversation'),
    path('markdownx/', include('markdownx.urls')),
]

# django documented recommended pattern
# TODO: refactor all this for S3, both local and production
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
