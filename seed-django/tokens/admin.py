from django.contrib import admin
from .models import APIToken


@admin.register(APIToken)
class APITokenAdmin(admin.ModelAdmin):
    list_display = ("name", "user", "created_at")
    list_filter = ("user",)
    readonly_fields = ("token", "created_at")
