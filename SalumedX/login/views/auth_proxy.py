"""
Vista proxy para redirigir login al auth-service
Útil si el frontend ya usa estas rutas y no quieres cambiarlas
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
import requests
from django.conf import settings

AUTH_SERVICE_URL = getattr(settings, 'AUTH_SERVICE_URL', 'http://localhost:8001')


@api_view(['POST'])
@permission_classes([AllowAny])
def signin_proxy(request):
    """
    Proxy para login - redirige al auth-service
    """
    try:
        response = requests.post(
            f'{AUTH_SERVICE_URL}/auth/login',
            json=request.data,
            timeout=5
        )
        
        return Response(
            response.json(),
            status=response.status_code
        )
    except requests.exceptions.RequestException as e:
        return Response({
            'error': 'Auth service no disponible',
            'detail': str(e)
        }, status=503)


@api_view(['POST'])
@permission_classes([AllowAny])
def signup_proxy(request):
    """
    Proxy para registro - redirige al auth-service
    """
    try:
        response = requests.post(
            f'{AUTH_SERVICE_URL}/auth/register',
            json=request.data,
            timeout=5
        )
        
        return Response(
            response.json(),
            status=response.status_code
        )
    except requests.exceptions.RequestException as e:
        return Response({
            'error': 'Auth service no disponible',
            'detail': str(e)
        }, status=503)
