from django.db import models
from django.contrib.auth.models import User
from django.urls import reverse

from markdownx.models import MarkdownxField
from markdownx.utils import markdownify
from PIL import Image

# TODO: add tag/category? tech, research, general -- single github repo for all experiments/ai_research?
class Post(models.Model):
    title = models.CharField(max_length=100)
    body = MarkdownxField()
    date_posted = models.DateTimeField(auto_now_add=True)
    date_updated = models.DateTimeField(auto_now=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    summary = models.CharField(max_length=500)
    image = models.ImageField(default="kairos_default.jpg")
    conversation_file = models.CharField(max_length=100, null=True, blank=True)

    img_size = (2400, 1600)

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        return reverse("post-detail", kwargs={"pk": self.pk})

    def formatted_markdown(self):
        return markdownify(self.body)

    def save(self):
        super().save()

        image = Image.open(self.image.path)
        image.thumbnail(self.img_size)
        image.save(self.image.path)
