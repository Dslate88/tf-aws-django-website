from django.views import generic
from .models import Post


class HomeView(generic.ListView):
    model = Post
    template_name = "blog/home.html"
