import os

from django.core.files.storage import FileSystemStorage
from storages.backends.s3boto3 import S3Boto3Storage

# TODO: disable DNS for domainname while in development


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
    location = "test_media"
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
