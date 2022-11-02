from django.db.models.signals import post_save
from django.contrib.auth.models import User
from django.dispatch import receiver
from .models import Profile


@receiver(post_save, sender=User)  # upon User data model object save
def create_profile(sender, instance, created, **kwargs):
    """
    Signal Dispatcher Sender (handler)

    When a User is saved in the data model then send a post_save signal.
    Signal received by this function, if signal received has a created state
    then create a Profile for the User of the received instance.
    """
    if created:
        Profile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_profile(sender, instance, **kwargs):
    """
    Signal Dispatcher Sender (handler)

    When a User is saved in the data model then send a post_save signal.
    Signal received by this function, if the signal received instance is saved
    for that user, then save the Profile.
    """
    instance.profile.save()
