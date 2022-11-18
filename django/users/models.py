import os

from django.db import models
from django.contrib.auth.models import User
from django.core.files.storage import FileSystemStorage
from storages.backends.s3boto3 import S3Boto3Storage

from PIL import Image


class PrivateMediaStorage(S3Boto3Storage):
    """
    This class is used to store media files on AWS S3

    Args:
        S3Boto3Storage (class): This class is used to store media files on S3Boto3Storage

    Attributes:
        location (str): The location of the media files
        default_acl (str): The default access control list for the media files
        bucket_name (str): The name of the S3 bucket

    """

    default_acl = "private"
    file_overwrite = False
    bucket_name = "account-keeps-nonversioned"  # TODO: var me


def get_storage():
    """
    This function isolates local media from production s3 media

    Returns:
        [class]: [the storage class]

    """
    if os.environ["DEPLOY_ENV"] == "prod":
        return PrivateMediaStorage()
    else:
        return FileSystemStorage()


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
