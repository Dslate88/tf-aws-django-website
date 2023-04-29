from django.db import models
from django.contrib.auth.models import User
from django.urls import reverse

# TODO: convert body to markdown object, test image emedding? or just keep html???
class Post(models.Model):
    title = models.CharField(max_length=100)
    body = models.TextField()
    date_posted = models.DateTimeField(auto_now_add=True)
    date_updated = models.DateTimeField(auto_now=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE)

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        return reverse("post-detail", kwargs={"pk": self.pk})
