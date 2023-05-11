import json

from django.views import generic
from django.urls import reverse_lazy
from django.shortcuts import get_object_or_404, render
from django.http import Http404

from .models import Post, User


class HomeView(generic.ListView):
    """TODO: queryset or paginate approach"""

    model = Post
    template_name = "blog/home.html"
    context_object_name = "post_list"


class AboutView(generic.ListView):
    """place holder for now, static asset later..?"""

    model = User
    template_name = "blog/about.html"
    context_object_name = "profile"

    def get_queryset(self):  # TODO: replace with static? or Author data_model...?
        return Post.objects.order_by("-date_posted")[:5]


class PostCreateView(generic.CreateView):
    model = Post
    fields = ["title", "body"]
    template_name = "blog/post_form.html"

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)


class PostUpdateView(generic.UpdateView):
    model = Post
    fields = ["title", "body"]
    template_name = "blog/post_form.html"

class PostDetailView(generic.DetailView):
    model = Post
    template_name = "blog/post_detail.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        post = get_object_or_404(Post, pk=self.kwargs.get('pk'))
        if post.conversation_file:
            try:
                with open(f'static/conversations/{post.conversation_file}.json', 'r') as f:
                    conversation = json.load(f)
            except FileNotFoundError:
                conversation = []  # TODO: or handle this error differently
        else:
            conversation = [] # TODO: handle

        context['conversation'] = conversation
        return context

class PostDeleteView(generic.DeleteView):
    model = Post
    template_name = "blog/post_confirm_delete.html"
    success_url = reverse_lazy("blog-home")
