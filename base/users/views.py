from django.views import generic
from django.urls import reverse_lazy
from django.contrib.auth.forms import UserCreationForm


class UserRegister(generic.CreateView):
    form_class = UserCreationForm
    template_name = "users/register.html"
    success_url = reverse_lazy("login")
