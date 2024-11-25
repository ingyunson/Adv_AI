from django.urls import path
from api import app as fastapi_app
from django_fastapi_asgi import FastAPIHandler

urlpatterns = [
    path("api/", FastAPIHandler(fastapi_app)),
]
