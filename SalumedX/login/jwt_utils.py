"""
Utilidades para manejo de JWT desde auth-service
Funciones auxiliares para trabajar con tokens, expiración y payload
"""
import jwt
from datetime import datetime, timedelta
from django.conf import settings


def get_token_expiration_time(token):
    """
    Obtiene el tiempo de expiración de un token JWT
    
    Args:
        token (str): Token JWT
        
    Returns:
        datetime: Fecha y hora de expiración, o None si el token es inválido
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256'],
            options={'verify_exp': False}  # No verificar expiración aquí
        )
        
        exp_timestamp = payload.get('exp')
        if exp_timestamp:
            return datetime.fromtimestamp(exp_timestamp)
        
        return None
    except:
        return None


def get_token_remaining_time(token):
    """
    Calcula el tiempo restante hasta que expire el token
    
    Args:
        token (str): Token JWT
        
    Returns:
        timedelta: Tiempo restante, o None si ya expiró o es inválido
    """
    exp_time = get_token_expiration_time(token)
    if not exp_time:
        return None
    
    now = datetime.now()
    if now >= exp_time:
        return None  # Ya expiró
    
    return exp_time - now


def is_token_expired(token):
    """
    Verifica si un token JWT ha expirado
    
    Args:
        token (str): Token JWT
        
    Returns:
        bool: True si expiró, False si aún es válido
    """
    try:
        jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256']
        )
        return False  # Token válido, no ha expirado
    except jwt.ExpiredSignatureError:
        return True  # Token expirado
    except:
        return True  # Otro error = considerar como expirado


def get_token_payload(token):
    """
    Extrae el payload completo de un token JWT
    
    Args:
        token (str): Token JWT
        
    Returns:
        dict: Payload del token, o None si es inválido
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256'],
            options={'verify_exp': False}
        )
        return payload
    except:
        return None


def get_user_id_from_token(token):
    """
    Extrae el user_id del payload de un token JWT
    
    Args:
        token (str): Token JWT
        
    Returns:
        int: ID del usuario, o None si no se encuentra
    """
    payload = get_token_payload(token)
    if payload:
        return payload.get('user_id')
    return None


def format_remaining_time(remaining_time):
    """
    Formatea el tiempo restante en un string legible
    
    Args:
        remaining_time (timedelta): Tiempo restante
        
    Returns:
        str: Tiempo formateado (ej: "2h 15m", "30m", "5h")
    """
    if not remaining_time:
        return "Expirado"
    
    total_seconds = int(remaining_time.total_seconds())
    
    if total_seconds <= 0:
        return "Expirado"
    
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    
    if hours > 0:
        if minutes > 0:
            return f"{hours}h {minutes}m"
        return f"{hours}h"
    
    return f"{minutes}m"


def get_token_info(request):
    """
    Obtiene información completa sobre el token JWT del request
    
    Args:
        request: Request de Django
        
    Returns:
        dict: Información del token (user_id, expiración, tiempo restante, etc.)
    """
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    
    if not auth_header.startswith('Bearer '):
        return {
            'has_token': False,
            'error': 'No token provided'
        }
    
    token = auth_header.split(' ')[1]
    
    # Obtener información del token
    payload = get_token_payload(token)
    exp_time = get_token_expiration_time(token)
    remaining = get_token_remaining_time(token)
    expired = is_token_expired(token)
    
    info = {
        'has_token': True,
        'token': token[:20] + '...' if len(token) > 20 else token,
        'expired': expired,
        'user_id': payload.get('user_id') if payload else None,
        'expiration_time': exp_time.isoformat() if exp_time else None,
        'remaining_time': format_remaining_time(remaining) if remaining else 'Expirado',
        'remaining_seconds': int(remaining.total_seconds()) if remaining else 0
    }
    
    # Agregar información adicional del payload
    if payload:
        info['payload'] = {
            'username': payload.get('username'),
            'email': payload.get('email'),
            'tipo_usuario': payload.get('tipo_usuario'),
            'is_staff': payload.get('is_staff', False)
        }
    
    return info
