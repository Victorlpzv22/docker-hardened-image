"""
Django Hardening Demo - Main Application
Simple API for demonstrating Docker security best practices
"""
import os
import platform
import socket
from django.http import JsonResponse
from django.views import View


def health_check(request):
    """Health check endpoint for Docker HEALTHCHECK"""
    return JsonResponse({
        'status': 'healthy',
        'service': 'docker-hardening-demo'
    })


def api_info(request):
    """System information endpoint"""
    return JsonResponse({
        'hostname': socket.gethostname(),
        'platform': platform.system(),
        'python_version': platform.python_version(),
        'user': os.getenv('USER', os.getenv('USERNAME', 'unknown')),
        'environment': os.getenv('DJANGO_ENV', 'development'),
        'debug': os.getenv('DEBUG', 'False'),
    })


def index(request):
    """Root endpoint"""
    return JsonResponse({
        'message': 'Docker Hardening Demo API (Django)',
        'version': '1.0.0',
        'endpoints': ['/health/', '/api/info/']
    })
