from django.views import generic
from .models import Post


class HomeView(generic.ListView):
    """TODO: queryset or paginate approach"""

    model = Post
    template_name = "blog/home.html"
    context_object_name = "post_list"
