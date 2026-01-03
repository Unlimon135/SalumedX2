from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken as JWT_RefreshToken
from django.utils import timezone
from datetime import timedelta
import jwt
from django.conf import settings

from authentication.models import User, RefreshToken
from authentication.serializers import (
    UserRegisterSerializer,
    UserLoginSerializer,
    UserSerializer
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


@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    """
    POST /auth/register/
    Registrar un nuevo usuario (farmaceutico o cliente)
    """
    serializer = UserRegisterSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()

        # Generar tokens
        refresh = JWT_RefreshToken.for_user(user)
        access = refresh.access_token

        # Agregar tipo_usuario al token
        access['tipo_usuario'] = user.tipo_usuario
        refresh['tipo_usuario'] = user.tipo_usuario

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
def login_view(request):
    """
    POST /auth/login/
    Iniciar sesión y obtener tokens JWT
    """
    serializer = UserLoginSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.validated_data['user']

        # Generar tokens
        refresh = JWT_RefreshToken.for_user(user)
        access = refresh.access_token

        # Agregar tipo_usuario al token
        access['tipo_usuario'] = user.tipo_usuario
        refresh['tipo_usuario'] = user.tipo_usuario

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

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def me_view(request):
    """
    GET /auth/me/
    Obtener información del usuario autenticado
    """
    return Response(UserSerializer(request.user).data)


@api_view(['POST'])
def register_cliente_view(request):
    """
    POST /auth/register-cliente/
    Farmaceutico registra un nuevo cliente
    Requiere autenticación de farmaceutico
    """
    # Verificar que el usuario autenticado sea farmaceutico
    if request.user.tipo_usuario != 'farmaceutico':
        return Response(
            {'error': 'Solo los farmaceuticos pueden registrar clientes'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    # Forzar tipo_usuario a cliente
    data = request.data.copy()
    data['tipo_usuario'] = 'cliente'
    
    serializer = UserRegisterSerializer(data=data)
    
    if serializer.is_valid():
        user = serializer.save()
        
        return Response({
            'message': 'Cliente registrado exitosamente',
            'user': UserSerializer(user).data
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
