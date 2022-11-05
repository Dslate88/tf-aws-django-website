from django.contrib import messages
from django.contrib.messages.views import SuccessMessageMixin
from django.shortcuts import render, redirect
from django.urls import reverse_lazy
from django.views import generic

from .forms import UserRegisterForm, UserUpdateForm, ProfileUpdateForm


class UserRegisterView(SuccessMessageMixin, generic.CreateView):
    """
    Render form and return http response for user registration
    """

    template_name = "users/register.html"
    form_class = UserRegisterForm
    success_url = reverse_lazy("user-login")
    success_message = "Hey %(username)s, your account was created!"


class UserProfileView(generic.View):
    """
    Enables 1(view):1(url) mapping for both get and post requests.

    Forms:
        - ProfileUpdateForm
        - UserUpdateForm
    """

    template_name = "users/profile.html"
    user_form_class = UserUpdateForm
    profile_form_class = ProfileUpdateForm
    success_url = reverse_lazy("user-profile")

    def get(self, request, *args, **kwargs):
        user_form = self.user_form_class(instance=request.user)
        profile_form = self.profile_form_class(instance=request.user.profile)
        return render(
            request,
            self.template_name,
            {"user_form": user_form, "profile_form": profile_form},
        )

    def post(self, request, *args, **kwargs):
        user_form = self.user_form_class(request.POST, instance=request.user)
        profile_form = self.profile_form_class(
            request.POST, request.FILES, instance=request.user.profile
        )

        if user_form.is_valid() and profile_form.is_valid():
            user_form.save()
            profile_form.save()
            messages.success(request, "Profile details updated.")
            return redirect(self.success_url)
        else:
            return render(
                request,
                self.template_name,
                {"user_form": user_form, "profile_form": profile_form},
            )
