import secrets

from django.contrib.auth.models import User
from django.db import models


class APIToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="api_tokens")
    token = models.CharField(max_length=64, unique=True, db_index=True)
    name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name} ({self.user.email})"

    @classmethod
    def generate(cls, user: User, name: str) -> "APIToken":
        return cls.objects.create(
            user=user,
            token=secrets.token_urlsafe(48),
            name=name,
        )
