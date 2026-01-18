"""
Django Hardening Demo - URL Configuration
"""
from django.urls import path
from demo import views

urlpatterns = [
    path('', views.index, name='index'),
    path('health/', views.health_check, name='health'),
    path('api/info/', views.api_info, name='api_info'),
]
