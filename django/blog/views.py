import json

from django.views import generic
from django.urls import reverse_lazy
from django.shortcuts import get_object_or_404

from .models import Post, User

# TODO: paginate
class HomeView(generic.ListView):
    """
    View for listing all blog posts on the home page.
    """
    model = Post
    template_name = "blog/home.html"
    context_object_name = "post_list"

    def get_queryset(self):
        return Post.objects.order_by('-date_posted')

class AboutView(generic.ListView):
    """
    View for the About page.
    """
    model = User
    template_name = "blog/about.html"
    context_object_name = "profile"

class PostDetailView(generic.DetailView):
    model = Post
    template_name = "blog/post_detail.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        post = self.object
        if post.conversation_file:
            with open(f'static/conversations/{post.conversation_file}', 'r') as f:
                conversation = json.load(f)
            conversation_dict = {msg['idx']: msg for msg in conversation}
            context['conversation'] = conversation_dict
        return context

class ConversationView(generic.DetailView):
    model = Post
    template_name = "blog/conversation_full.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        post = get_object_or_404(Post, pk=self.kwargs.get('pk'))
        if post.conversation_file:
            try:
                with open(f'static/conversations/{post.conversation_file}', 'r') as f:
                    conversation = json.load(f)
            except FileNotFoundError:
                conversation = []
        else:
            conversation = []

        context['conversation'] = conversation
        return context

