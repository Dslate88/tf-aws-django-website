from django.contrib import admin
from .models import Profile
from markdownx.admin import MarkdownxModelAdmin


admin.site.register(Profile, MarkdownxModelAdmin)
