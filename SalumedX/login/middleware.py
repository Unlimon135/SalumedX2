"""
Middleware para validación local de JWT desde Auth Service
Valida tokens sin hacer llamadas al auth-service en cada request
Maneja automáticamente la expiración de tokens
"""
import jwt
from datetime import datetime
from django.conf import settings
from django.http import JsonResponse
from django.utils.functional import SimpleLazyObject
from django.contrib.auth.models import AnonymousUser
from login.models import User


def get_user_from_jwt(request):
    """
    Extrae y valida el token JWT del header Authorization
    Retorna el usuario si el token es válido, None si hay error o ha expirado
    """
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    
    if not auth_header.startswith('Bearer '):
        return None
    
    token = auth_header.split(' ')[1]
    
    try:
        # Validar token localmente (firma + expiración automática)
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256']
        )
        
        # Extraer información del payload
        user_id = payload.get('user_id')
        
        if not user_id:
            return None
        
        # Verificar expiración adicional (aunque jwt.decode ya lo hace)
        exp_timestamp = payload.get('exp')
        if exp_timestamp:
            exp_datetime = datetime.fromtimestamp(exp_timestamp)
            if datetime.now() > exp_datetime:
                # Token expirado
                request.jwt_expired = True
                return None
        
        # Obtener usuario de la base de datos local
        try:
            user = User.objects.get(id=user_id)
            if not user.is_active:
                return None
            
            # Guardar información adicional del token
            request.jwt_payload = payload
            request.jwt_expired = False
            
            return user
        except User.DoesNotExist:
            return None
            
    except jwt.ExpiredSignatureError:
        # Token expirado
        request.jwt_expired = True
        request.jwt_error = 'Token expirado'
        return None
    except jwt.InvalidTokenError as e:
        # Token inválido
        request.jwt_error = f'Token inválido: {str(e)}'
        return None
    except Exception as e:
        # Otro error
        request.jwt_error = f'Error al validar token: {str(e)}'
        return None


class JWTAuthenticationMiddleware:
    """
    Middleware que valida JWT localmente desde auth-service
    - Valida tokens sin llamar al auth-service en cada request
    - Maneja automáticamente la expiración
    - Asigna request.user para compatibilidad con DRF
    - Proporciona información de errores y expiración
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Inicializar flags
        request.jwt_expired = False
        request.jwt_error = None
        request.jwt_payload = None
        
        # Extraer usuario del JWT
        jwt_user = get_user_from_jwt(request)
        
        # Asignar jwt_user (lazy)
        request.jwt_user = jwt_user
        
        # Asignar request.user para compatibilidad con DRF
        # Si no hay sesión de Django activa, usar el usuario JWT
        if not hasattr(request, 'user') or isinstance(request.user, AnonymousUser):
            if jwt_user:
                request.user = jwt_user
        
        response = self.get_response(request)
        
        # Agregar headers informativos sobre el token
        if request.jwt_expired:
            response['X-Token-Status'] = 'expired'
            response['X-Token-Error'] = request.jwt_error or 'Token expirado'
        elif request.jwt_error:
            response['X-Token-Status'] = 'invalid'
            response['X-Token-Error'] = request.jwt_error
        elif jwt_user:
            response['X-Token-Status'] = 'valid'
        
        return response
