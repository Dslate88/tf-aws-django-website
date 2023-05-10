from django.db import models
from django.contrib.auth.models import User

from PIL import Image


class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    image = models.ImageField(default="kairos_default.jpg")
    img_size = (2400, 1600)

    def __str__(self):
        return f"Profile:{self.user.username}"

    def save(self):
        super().save()

        image = Image.open(self.image.path)
        image.thumbnail(self.img_size)
        image.save(self.image.path)
