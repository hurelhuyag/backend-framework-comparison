from django.db import models

class Category(models.Model):
    parent = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name='children'
    )
    name = models.TextField()

    class Meta:
        db_table = 'category'
        managed = False
        unique_together = ('parent', 'name')

    def __str__(self):
        return self.name


class Content(models.Model):
    category = models.ForeignKey(
        Category,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name='contents'
    )
    content = models.TextField()

    class Meta:
        db_table = 'content'
        managed = False

    def __str__(self):
        return f"{self.id}: {self.content[:30]}"
