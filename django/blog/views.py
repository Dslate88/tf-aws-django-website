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

class AboutView(generic.ListView):
    """
    View for the About page.
    """
    model = User
    template_name = "blog/about.html"
    context_object_name = "profile"

class PostCreateView(generic.CreateView):
    """
    View for creating a new blog post.
    """
    model = Post
    fields = ["title", "body"]
    template_name = "blog/post_form.html"

    def form_valid(self, form):
        """
        Add the logged-in user as the author of the post.

        :param form: The form instance
        :return: super().form_valid(form)
        """
        form.instance.author = self.request.user
        return super().form_valid(form)

# TODO: rm and just keep admin?
class PostUpdateView(generic.UpdateView):
    """
    View for updating an existing blog post.
    """
    model = Post
    fields = ["title", "body"]
    template_name = "blog/post_form.html"

class PostDetailView(generic.DetailView):
    """
    View for displaying a single blog post in detail.
    """
    model = Post
    template_name = "blog/post_detail.html"

    def get_context_data(self, **kwargs):
        """
        If a post has a related conversation file, add the conversation data to the context.

        :param kwargs: Additional keyword arguments
        :return: context
        """
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

# TODO: rm and just keep admin?
class PostDeleteView(generic.DeleteView):
    """
    View for deleting a blog post.
    """
    model = Post
    template_name = "blog/post_confirm_delete.html"
    success_url = reverse_lazy("blog-home")
