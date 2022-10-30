from django.contrib.auth.decorators import login_required
from django.urls import reverse_lazy
from django.shortcuts import render
from django.views import generic


from .forms import UserRegisterForm


class UserRegister(generic.CreateView):
    form_class = UserRegisterForm
    template_name = "users/register.html"
    success_url = reverse_lazy("user-login")


@login_required
def profile(request):
    """TODO: finish, include image upload, backend s3"""
    return render(request, "users/profile.html")
