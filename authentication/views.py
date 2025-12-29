from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken as JWT_RefreshToken
from rest_framework_simplejwt.exceptions import TokenError, InvalidToken
from django.contrib.auth.models import User
from django.utils import timezone
from django_ratelimit.decorators import ratelimit
from datetime import timedelta
import jwt
from django.conf import settings

from .models import RefreshToken, RevokedToken
from .serializers import (
    UserRegisterSerializer,
    UserLoginSerializer,
    UserSerializer,
    TokenRefreshSerializer,
    TokenValidateSerializer
)


def get_client_ip(request):
    """Obtener IP del cliente"""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip


def save_refresh_token(user, refresh_token, request):
    """Guardar refresh token en base de datos"""
    decoded_token = jwt.decode(
        str(refresh_token),
        options={"verify_signature": False}
    )
    
    RefreshToken.objects.create(
        user=user,
        token=str(refresh_token),
        jti=decoded_token['jti'],
        expires_at=timezone.now() + settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'],
        ip_address=get_client_ip(request),
        user_agent=request.META.get('HTTP_USER_AGENT', '')[:500]
    )


def is_token_revoked(jti):
    """Verificar si un token está revocado"""
    return RevokedToken.objects.filter(jti=jti).exists()


@api_view(['POST'])
@permission_classes([AllowAny])
@ratelimit(key='ip', rate='3/h', method='POST')
def register_view(request):
    """
    POST /auth/register
    Registrar un nuevo usuario
    """
    serializer = UserRegisterSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        
        # Generar tokens
        refresh = JWT_RefreshToken.for_user(user)
        access = refresh.access_token
        
        # Guardar refresh token
        save_refresh_token(user, refresh, request)
        
        return Response({
            'message': 'Usuario registrado exitosamente',
            'user': UserSerializer(user).data,
            'tokens': {
                'access': str(access),
                'refresh': str(refresh),
            }
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
@ratelimit(key='ip', rate='5/h', method='POST')
def login_view(request):
    """
    POST /auth/login
    Iniciar sesión y obtener tokens JWT
    """
    serializer = UserLoginSerializer(data=request.data, context={'request': request})
    
    if serializer.is_valid():
        user = serializer.validated_data['user']
        
        # Actualizar último login
        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])
        
        # Generar tokens
        refresh = JWT_RefreshToken.for_user(user)
        access = refresh.access_token
        
        # Guardar refresh token
        save_refresh_token(user, refresh, request)
        
        return Response({
            'message': 'Login exitoso',
            'user': UserSerializer(user).data,
            'tokens': {
                'access': str(access),
                'refresh': str(refresh),
            }
        }, status=status.HTTP_200_OK)
    
    return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """
    POST /auth/logout
    Cerrar sesión y revocar tokens
    """
    try:
        refresh_token = request.data.get('refresh')
        
        if refresh_token:
            # Decodificar token
            decoded_token = jwt.decode(
                refresh_token,
                options={"verify_signature": False}
            )
            jti = decoded_token['jti']
            exp = decoded_token['exp']
            
            # Revocar refresh token
            RevokedToken.objects.create(
                jti=jti,
                token_type='refresh',
                user=request.user,
                expires_at=timezone.datetime.fromtimestamp(exp),
                reason='logout'
            )
            
            # Eliminar de la tabla de refresh tokens
            RefreshToken.objects.filter(jti=jti).delete()
        
        return Response({
            'message': 'Logout exitoso'
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'error': 'Error al cerrar sesión',
            'detail': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def refresh_view(request):
    """
    POST /auth/refresh
    Obtener nuevo access token usando refresh token
    """
    serializer = TokenRefreshSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    refresh_token = serializer.validated_data['refresh']
    
    try:
        # Decodificar para verificar JTI
        decoded_token = jwt.decode(
            refresh_token,
            options={"verify_signature": False}
        )
        jti = decoded_token['jti']
        
        # Verificar si está revocado
        if is_token_revoked(jti):
            return Response({
                'error': 'Token revocado'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Verificar si existe en la base de datos
        token_obj = RefreshToken.objects.filter(jti=jti).first()
        if not token_obj:
            return Response({
                'error': 'Token no válido'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Generar nuevo access token
        refresh = JWT_RefreshToken(refresh_token)
        access = refresh.access_token
        
        return Response({
            'access': str(access),
        }, status=status.HTTP_200_OK)
    
    except TokenError as e:
        return Response({
            'error': 'Token inválido o expirado',
            'detail': str(e)
        }, status=status.HTTP_401_UNAUTHORIZED)
    except Exception as e:
        return Response({
            'error': 'Error al refrescar token',
            'detail': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me_view(request):
    """
    GET /auth/me
    Obtener información del usuario autenticado
    """
    serializer = UserSerializer(request.user)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def validate_view(request):
    """
    POST /auth/validate
    Validar un token JWT (para otros microservicios)
    """
    serializer = TokenValidateSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    token = serializer.validated_data['token']
    
    try:
        # Decodificar token
        decoded_token = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256']
        )
        
        jti = decoded_token.get('jti')
        user_id = decoded_token.get('user_id')
        
        # Verificar si está revocado
        if is_token_revoked(jti):
            return Response({
                'valid': False,
                'error': 'Token revocado'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Obtener usuario
        try:
            user = User.objects.get(id=user_id)
            
            return Response({
                'valid': True,
                'user': UserSerializer(user).data,
                'exp': decoded_token.get('exp'),
            }, status=status.HTTP_200_OK)
        
        except User.DoesNotExist:
            return Response({
                'valid': False,
                'error': 'Usuario no encontrado'
            }, status=status.HTTP_404_NOT_FOUND)
    
    except jwt.ExpiredSignatureError:
        return Response({
            'valid': False,
            'error': 'Token expirado'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    except jwt.InvalidTokenError as e:
        return Response({
            'valid': False,
            'error': 'Token inválido',
            'detail': str(e)
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    except Exception as e:
        return Response({
            'valid': False,
            'error': 'Error al validar token',
            'detail': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)
