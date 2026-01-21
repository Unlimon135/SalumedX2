"""
Decoradores para autenticación JWT desde auth-service
Maneja validación de tokens, expiración y errores
"""
from functools import wraps
from django.http import JsonResponse


def jwt_required(view_func):
    """
    Decorador que requiere un token JWT válido del auth-service
    Maneja automáticamente la expiración y errores de token
    
    Uso: @jwt_required
    
    Respuestas de error:
    - 401: Token ausente, inválido o expirado
    - 403: Usuario inactivo
    """
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        # Verificar si hay un usuario autenticado vía JWT
        if hasattr(request, 'jwt_user') and request.jwt_user:
            # Token válido y usuario activo
            return view_func(request, *args, **kwargs)
        
        # Verificar si el token expiró
        if hasattr(request, 'jwt_expired') and request.jwt_expired:
            return JsonResponse({
                'error': 'Token expirado',
                'detail': 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
                'code': 'TOKEN_EXPIRED'
            }, status=401)
        
        # Verificar si hubo otro error con el token
        if hasattr(request, 'jwt_error') and request.jwt_error:
            return JsonResponse({
                'error': 'Token inválido',
                'detail': request.jwt_error,
                'code': 'TOKEN_INVALID'
            }, status=401)
        
        # No hay token
        return JsonResponse({
            'error': 'Autenticación requerida',
            'detail': 'Token JWT válido requerido en el header Authorization',
            'code': 'AUTH_REQUIRED'
        }, status=401)
    
    return wrapped_view


def jwt_optional(view_func):
    """
    Decorador que permite acceso con o sin JWT
    El usuario estará en request.jwt_user y request.user si está autenticado
    
    Uso: @jwt_optional
    
    Útil para endpoints que pueden funcionar con o sin autenticación
    (ej: listar productos públicamente vs. con precios personalizados)
    """
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        # Simplemente ejecuta la vista
        # El usuario JWT estará disponible en request.jwt_user si existe
        return view_func(request, *args, **kwargs)
    
    return wrapped_view


def jwt_required_staff(view_func):
    """
    Decorador que requiere un token JWT válido Y que el usuario sea staff/admin
    
    Uso: @jwt_required_staff
    
    Respuestas de error:
    - 401: Token ausente, inválido o expirado
    - 403: Usuario no es staff/admin
    """
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        # Verificar autenticación básica
        if not hasattr(request, 'jwt_user') or not request.jwt_user:
            if hasattr(request, 'jwt_expired') and request.jwt_expired:
                return JsonResponse({
                    'error': 'Token expirado',
                    'detail': 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
                    'code': 'TOKEN_EXPIRED'
                }, status=401)
            
            return JsonResponse({
                'error': 'Autenticación requerida',
                'detail': 'Token JWT válido requerido',
                'code': 'AUTH_REQUIRED'
            }, status=401)
        
        # Verificar permisos de staff
        if not request.jwt_user.is_staff:
            return JsonResponse({
                'error': 'Permisos insuficientes',
                'detail': 'Se requieren permisos de administrador',
                'code': 'INSUFFICIENT_PERMISSIONS'
            }, status=403)
        
        return view_func(request, *args, **kwargs)
    
    return wrapped_view
