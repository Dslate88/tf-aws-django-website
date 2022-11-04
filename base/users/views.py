from django.urls import reverse_lazy
from django.views import generic
from django.contrib.auth.models import User
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib.messages.views import SuccessMessageMixin

# from users.models import Profile
from .forms import UserRegisterForm, UserUpdateForm, ProfileUpdateForm


class UserRegisterView(SuccessMessageMixin, generic.CreateView):
    """
    Render form and return http response for user registration
    """

    form_class = UserRegisterForm
    template_name = "users/register.html"
    success_url = reverse_lazy("user-login")
    success_message = "Hey %(username)s, your account was created!"


class UserProfileView(LoginRequiredMixin, generic.ListView):
    """
    Render form
    Return http response for Profile access

    TODO: finish, include image upload, backend s3
    TODO: needs custom data model to handle additional fields into forms?
    """

    model = User
    template_name = "users/profile.html"
    login_url = "user-login"


class UserProfileUpdateView(LoginRequiredMixin, generic.UpdateView):
    """
    Render user and profile forms
    """

    model = User
    template_name = "users/profile_update.html"
    success_url = reverse_lazy("user-profile")
    form_class = UserUpdateForm

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["user_form"] = UserUpdateForm()
        context["profile_form"] = ProfileUpdateForm()
        return context
