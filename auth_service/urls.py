"""
URL configuration for auth_service project.
Microservicio de Autenticación
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse


def health_check(request):
    """Endpoint para verificar el estado del servicio"""
    return JsonResponse({
        'status': 'healthy',
        'service': 'auth-service',
        'version': '1.0.0'
    })


urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('authentication.urls')),
    path('health/', health_check, name='health_check'),
]
