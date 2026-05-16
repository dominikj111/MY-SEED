from django.urls import path
from . import views

# These patterns are mounted under `py/` in config/urls.py.
# Resulting URLs: /py/, /py/login/, /py/dashboard/, /py/contact/, /py/logout/
urlpatterns = [
    path("", views.index, name="py_index"),
    path("login/", views.login_view, name="py_login"),
    path("logout/", views.logout_view, name="py_logout"),
    path("dashboard/", views.dashboard, name="py_dashboard"),
    path("contact/", views.contact, name="py_contact"),
]
