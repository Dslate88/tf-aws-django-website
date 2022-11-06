from django.views import generic
from .models import Post


class HomeView(generic.ListView):
    """TODO: queryset or paginate approach"""

    model = Post
    template_name = "blog/home.html"
    context_object_name = "post_list"


class AboutView(generic.ListView):
    """place holder for now, static asset later..?"""

    template_name = "blog/about.html"

    def get_queryset(self):  # replace with static? or Author data_model...?
        return Post.objects.order_by("-date_posted")[:5]


class PostDetailView(generic.DetailView):
    model = Post
    template_name = "blog/post_detail.html"


class PostCreateView(generic.CreateView):
    model = Post
    fields = ["title", "body", "author"]
    template_name = "blog/post_create.html"
