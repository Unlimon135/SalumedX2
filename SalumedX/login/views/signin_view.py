from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import authenticate, login
from rest_framework_simplejwt.tokens import RefreshToken

@api_view(['POST'])
@permission_classes([AllowAny])
def signin(request):
    try:
        username = request.data.get('username')
        password = request.data.get('password')
        
        if not username or not password:
            return Response({"success": False, "error": "Usuario y contraseña son requeridos"}, status=400)
        
        user = authenticate(request, username=username, password=password)
        if user is not None:
            # Crear sesión (para soporte de cookies)
            login(request, user)
            
            # Generar tokens JWT (para API/GraphQL)
            refresh = RefreshToken.for_user(user)
            
            # Determinar tipo de usuario
            tipo_usuario = None
            perfil_data = None
            
            if hasattr(user, 'medico'):
                tipo_usuario = 'medico'
                perfil_data = {
                    'numero_licencia': user.medico.numero_licencia,
                    'institucion': user.medico.institucion,
                    'ubicacion_consultorio': user.medico.ubicacion_consultorio
                }
            elif hasattr(user, 'paciente'):
                tipo_usuario = 'paciente'
                perfil_data = {
                    'cedula': user.paciente.cedula,
                    'fecha_nacimiento': str(user.paciente.fecha_nacimiento),
                    'direccion': user.paciente.direccion,
                    'telefono': user.paciente.telefono
                }
            
            return Response({
                "success": True,
                "message": "Login exitoso",
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "email": user.email,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "tipo_usuario": tipo_usuario,
                    "perfil": perfil_data
                }
            })
        else:
            return Response({"success": False, "error": "El usuario o la contraseña son incorrectos"}, status=400)
    except Exception as e:
        return Response({"success": False, "error": f"Error en el servidor: {str(e)}"}, status=500)