#!/usr/bin/env python
"""
Script para ejecutar el servidor de desarrollo en el puerto 8001
"""
import os
import sys

if __name__ == "__main__":
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'auth_service.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    
    # Ejecutar en puerto 8001
    sys.argv = ['manage.py', 'runserver', '0.0.0.0:8001']
    execute_from_command_line(sys.argv)
