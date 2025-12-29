"""
Middleware para validación local de JWT desde Auth Service
Valida tokens sin hacer llamadas al auth-service en cada request
"""
import jwt
from django.conf import settings
from django.http import JsonResponse
from django.utils.functional import SimpleLazyObject
from rest_framework_simplejwt.exceptions import TokenError
from login.models import User


def get_user_from_jwt(request):
    """Extrae y valida el token JWT del header Authorization"""
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    
    if not auth_header.startswith('Bearer '):
        return None
    
    token = auth_header.split(' ')[1]
    
    try:
        # Validar token localmente (firma + expiración)
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256']
        )
        
        # Extraer user_id del payload
        user_id = payload.get('user_id')
        
        if not user_id:
            return None
        
        # Obtener usuario de la base de datos local
        try:
            user = User.objects.get(id=user_id)
            return user if user.is_active else None
        except User.DoesNotExist:
            return None
            
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
    except Exception:
        return None


class JWTAuthenticationMiddleware:
    """
    Middleware que valida JWT localmente
    No requiere llamadas al auth-service para cada request
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Agregar el usuario al request si hay un token válido
        request.jwt_user = SimpleLazyObject(lambda: get_user_from_jwt(request))
        
        response = self.get_response(request)
        return response
