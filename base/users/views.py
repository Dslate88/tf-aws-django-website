from django.views import generic
from django.urls import reverse_lazy

from .forms import UserRegisterForm


class UserRegister(generic.CreateView):
    form_class = UserRegisterForm
    template_name = "users/register.html"
    success_url = reverse_lazy("login")
