from django.db import models
from django.contrib.auth.models import User
from PIL import Image

from media_storage import get_storage


class Profile(models.Model):
    """
    This class is used to store user profile information

    Args:
        models (class): django default model class

    Attributes:
        user (ForeignKey): The user that the profile belongs to
        image (ImageField): The profile image
        img_size (tuple): The size of the profile image

    """

    user = models.OneToOneField(User, on_delete=models.CASCADE)
    image = models.ImageField(storage=get_storage(), default="kairos_default.jpg")
    img_size = (210, 210)

    def __str__(self):
        return f"Profile:{self.user.username}"

    def save(self):
        super().save()

        image = Image.open(self.image.path)
        image.thumbnail(self.img_size)
        image.save(self.image.path)
