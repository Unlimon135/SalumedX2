"""
Vista proxy para redirigir login/registro al auth-service
El auth-service (puerto 8001) devuelve tokens JWT que luego son validados localmente
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
    
    El auth-service devuelve:
    {
        "access": "<JWT_TOKEN>",
        "refresh": "<REFRESH_TOKEN>",
        "user": {...}
    }
    
    Este token debe ser usado en requests posteriores:
    Authorization: Bearer <JWT_TOKEN>
    """
    try:
        response = requests.post(
            f'{AUTH_SERVICE_URL}/auth/login',
            json=request.data,
            timeout=5
        )
        
        data = response.json()
        
        # Agregar información sobre el uso del token
        if response.status_code == 200 and 'access' in data:
            data['token_info'] = {
                'usage': 'Incluir en header: Authorization: Bearer <access_token>',
                'expires_in': '5 horas',
                'refresh_usage': 'Usar refresh token en /token/refresh/ para obtener nuevo access token'
            }
        
        return Response(data, status=response.status_code)
        
    except requests.exceptions.Timeout:
        return Response({
            'error': 'Auth service timeout',
            'detail': 'El servicio de autenticación no respondió a tiempo'
        }, status=504)
    except requests.exceptions.ConnectionError:
        return Response({
            'error': 'Auth service no disponible',
            'detail': 'No se pudo conectar al servicio de autenticación'
        }, status=503)
    except requests.exceptions.RequestException as e:
        return Response({
            'error': 'Auth service error',
            'detail': str(e)
        }, status=503)


@api_view(['POST'])
@permission_classes([AllowAny])
def signup_proxy(request):
    """
    Proxy para registro - redirige al auth-service
    
    El auth-service devuelve:
    {
        "access": "<JWT_TOKEN>",
        "refresh": "<REFRESH_TOKEN>",
        "user": {...}
    }
    
    Después del registro, el usuario recibe tokens automáticamente
    """
    try:
        response = requests.post(
            f'{AUTH_SERVICE_URL}/auth/register',
            json=request.data,
            timeout=5
        )
        
        data = response.json()
        
        # Agregar información sobre el uso del token
        if response.status_code == 201 and 'access' in data:
            data['token_info'] = {
                'usage': 'Incluir en header: Authorization: Bearer <access_token>',
                'expires_in': '5 horas',
                'refresh_usage': 'Usar refresh token en /token/refresh/ para obtener nuevo access token'
            }
        
        return Response(data, status=response.status_code)
        
    except requests.exceptions.Timeout:
        return Response({
            'error': 'Auth service timeout',
            'detail': 'El servicio de autenticación no respondió a tiempo'
        }, status=504)
    except requests.exceptions.ConnectionError:
        return Response({
            'error': 'Auth service no disponible',
            'detail': 'No se pudo conectar al servicio de autenticación'
        }, status=503)
    except requests.exceptions.RequestException as e:
        return Response({
            'error': 'Auth service error',
            'detail': str(e)
        }, status=503)
