from django.urls import reverse_lazy
from django.views import generic
from django.contrib.auth.models import User
from django.contrib.auth.mixins import LoginRequiredMixin

from .forms import UserRegisterForm


class UserRegister(generic.CreateView):
    form_class = UserRegisterForm
    template_name = "users/register.html"
    success_url = reverse_lazy("user-login")


class UserProfile(LoginRequiredMixin, generic.TemplateView):
    """
    TODO: finish, include image upload, backend s3
    TODO: needs custom data model to handle additional fields into forms?
    """

    login_url = "user-login"
    model = User
    template_name = "users/profile.html"
