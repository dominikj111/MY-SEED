from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("py/admin/", admin.site.urls),
    path("py/", include("web.urls")),
]
