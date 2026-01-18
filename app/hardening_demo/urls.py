"""
URL configuration for hardening_demo project.
"""
from django.urls import path, include

urlpatterns = [
    path('', include('demo.urls')),
]
