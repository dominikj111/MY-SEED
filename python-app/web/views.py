import logging

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.core.mail import send_mail
from django.shortcuts import redirect, render

from tokens.models import APIToken
from .forms import ContactForm

logger = logging.getLogger(__name__)


def index(request):
    return render(request, "web/index.html")


def login_view(request):
    if request.user.is_authenticated:
        return redirect("py_dashboard")

    error = None
    if request.method == "POST":
        user = authenticate(
            request,
            username=request.POST.get("email"),
            password=request.POST.get("password"),
        )
        if user:
            login(request, user)
            logger.info("User %s logged in", user.email)
            next_url = request.POST.get("next") or request.GET.get("next") or "/py/dashboard/"
            return redirect(next_url)
        error = "Invalid email or password."
        logger.warning("Failed login attempt for email=%s", request.POST.get("email"))

    return render(request, "web/login.html", {"error": error, "next": request.GET.get("next", "")})


def logout_view(request):
    if request.method == "POST":
        logger.info("User %s logged out", request.user.email if request.user.is_authenticated else "anonymous")
        logout(request)
    return redirect("py_index")


def dashboard(request):
    if not request.user.is_authenticated:
        return redirect(f"/py/login/?next={request.get_full_path()}")

    stats = {
        "user_count": User.objects.count(),
        "token_count": APIToken.objects.count(),
        "session_user": request.user,
    }
    tokens = APIToken.objects.filter(user=request.user).order_by("-created_at")
    return render(request, "web/dashboard.html", {"stats": stats, "tokens": tokens})


def contact(request):
    if not request.user.is_authenticated:
        return redirect(f"/py/login/?next={request.get_full_path()}")

    form = ContactForm()
    sent = False

    if request.method == "POST":
        form = ContactForm(request.POST)
        if form.is_valid():
            name = form.cleaned_data["name"]
            email = form.cleaned_data["email"]
            message = form.cleaned_data["message"]

            send_mail(
                subject=f"Contact from {name}",
                message=f"From: {name} <{email}>\n\n{message}",
                from_email=None,  # uses DEFAULT_FROM_EMAIL
                recipient_list=["admin@seed.local"],
            )
            logger.info("Contact email sent from %s <%s>", name, email)
            messages.success(request, "Your message was sent — check Mailpit!")
            sent = True
            form = ContactForm()

    return render(request, "web/contact.html", {"form": form, "sent": sent})
