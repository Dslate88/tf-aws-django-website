from django.db import models
from django.contrib.auth.models import User


class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    image = models.ImageField(default="kairos_default.jpg")

    def __str__(self):
        return f"Profile:{self.user.username}"
