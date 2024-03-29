from django.urls import path, include
from . import views


urlpatterns = [
    path("", views.HomeView.as_view(), name="blog-home"),
    path("about/", views.AboutView.as_view(), name="blog-about"),
    path('markdownx/', include('markdownx.urls')),
]
