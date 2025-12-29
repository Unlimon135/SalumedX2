"""
Decoradores simples para autenticación JWT
"""
from functools import wraps
from django.http import JsonResponse


def jwt_required(view_func):
    """
    Decorador que requiere un token JWT válido
    Uso: @jwt_required
    """
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        # Verificar si hay un usuario autenticado vía JWT
        if hasattr(request, 'jwt_user') and request.jwt_user:
            return view_func(request, *args, **kwargs)
        
        return JsonResponse({
            'error': 'Autenticación requerida',
            'detail': 'Token JWT válido requerido'
        }, status=401)
    
    return wrapped_view


def jwt_optional(view_func):
    """
    Decorador que permite acceso con o sin JWT
    El usuario estará en request.jwt_user si está autenticado
    Uso: @jwt_optional
    """
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        # Simplemente ejecuta la vista
        # El usuario JWT estará disponible si existe
        return view_func(request, *args, **kwargs)
    
    return wrapped_view
