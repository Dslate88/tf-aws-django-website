from django import forms
from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm

from .models import Profile


class UserRegisterForm(UserCreationForm):
    """
    Enable site visitors to create an account
    """

    # TODO: add first_name, last_name
    email = forms.EmailField()

    class Meta:
        model = User
        fields = ["username", "email", "password1", "password2"]


class UserUpdateForm(forms.ModelForm):
    """
    Enable registered users to update account details
    """

    email = forms.EmailField()

    class Meta:
        model = User
        fields = ["username", "email"]


class ProfileUpdateForm(forms.ModelForm):
    """
    Enable registered users to update profile image
    """

    class Meta:
        model = Profile
        fields = ["image"]
