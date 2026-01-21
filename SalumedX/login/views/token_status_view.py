"""
Vista para verificar el estado del token JWT
Permite al usuario consultar información sobre su sesión
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from login.jwt_utils import get_token_info


@api_view(['GET'])
@permission_classes([AllowAny])
def token_status(request):
    """
    GET: Verifica el estado del token JWT actual
    
    Responde con información sobre:
    - Si el token es válido
    - Tiempo de expiración
    - Tiempo restante
    - Usuario asociado
    
    Uso:
    GET /token-status/
    Header: Authorization: Bearer <token>
    """
    token_info = get_token_info(request)
    
    if not token_info['has_token']:
        return Response({
            'authenticated': False,
            'message': 'No se proporcionó un token JWT'
        }, status=401)
    
    if token_info['expired']:
        return Response({
            'authenticated': False,
            'expired': True,
            'message': 'El token ha expirado',
            'user_id': token_info.get('user_id'),
            'expiration_time': token_info.get('expiration_time')
        }, status=401)
    
    # Token válido
    return Response({
        'authenticated': True,
        'user_id': token_info['user_id'],
        'user_info': token_info.get('payload', {}),
        'expiration_time': token_info['expiration_time'],
        'remaining_time': token_info['remaining_time'],
        'remaining_seconds': token_info['remaining_seconds'],
        'message': 'Token válido'
    }, status=200)
