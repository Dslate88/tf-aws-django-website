from django.db import models
from django.contrib.auth.models import User
from django.urls import reverse

from markdownx.models import MarkdownxField
from markdownx.utils import markdownify
from PIL import Image

# TODO: add tag/category? tech, research, general -- single github repo for all experiments/ai_research?
class Post(models.Model):
    """
    Post model represents blog posts. Posts have title, body (markdown), timestamps,
    an author, a summary, an image, and optionally, a conversation file.
    """
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
        """
        String representation of a post object, which is its title.

        :return: str
        """
        return self.title

    def get_absolute_url(self):
        """
        Get the absolute URL of a post.

        :return: str
        """
        return reverse("post-detail", kwargs={"pk": self.pk})

    def formatted_markdown(self):
        """
        Convert markdown text in the body to formatted HTML.

        :return: str
        """
        return markdownify(self.body)

    def save(self):
        """
        Save a post and resize its associated image to fit within a specific size.
        """
        super().save()

        image = Image.open(self.image.path)
        image.thumbnail(self.img_size)
        image.save(self.image.path)
