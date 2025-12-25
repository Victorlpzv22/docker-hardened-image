"""
WSGI config for hardening_demo project.
"""
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hardening_demo.settings')
application = get_wsgi_application()
