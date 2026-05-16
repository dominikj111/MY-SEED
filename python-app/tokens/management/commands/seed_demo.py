import os

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from tokens.models import APIToken


class Command(BaseCommand):
    help = "Create the demo user and a demo API token (idempotent)."

    def handle(self, *args, **options):
        email = os.getenv("DEMO_USER_EMAIL", "admin@seed.local")
        password = os.getenv("DEMO_USER_PASSWORD", "password")
        username = email.split("@")[0]

        user, created = User.objects.get_or_create(
            email=email,
            defaults={"username": username, "is_staff": True, "is_superuser": True},
        )
        if created:
            user.set_password(password)
            user.save()
            self.stdout.write(f"[python] Demo user created: {email}")
        else:
            self.stdout.write(f"[python] Demo user already exists: {email}")

        # Create a demo token only if this user has none
        if not APIToken.objects.filter(user=user, name="Demo Token").exists():
            token = APIToken.generate(user, "Demo Token")
            self.stdout.write(f"[python] Demo API token: {token.token}")
        else:
            token = APIToken.objects.get(user=user, name="Demo Token")
            self.stdout.write(f"[python] Demo API token (existing): {token.token}")

        self.stdout.write(f"[python] Login: {email} / {password}")
