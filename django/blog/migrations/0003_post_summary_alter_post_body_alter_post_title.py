# Generated by Django 4.2.1 on 2023-05-10 18:03

from django.db import migrations, models
import markdownx.models


class Migration(migrations.Migration):

    dependencies = [
        ("blog", "0002_post_author"),
    ]

    operations = [
        migrations.AddField(
            model_name="post",
            name="summary",
            field=models.CharField(default=1, max_length=500),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name="post",
            name="body",
            field=markdownx.models.MarkdownxField(),
        ),
        migrations.AlterField(
            model_name="post",
            name="title",
            field=models.CharField(max_length=100),
        ),
    ]
