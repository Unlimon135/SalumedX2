from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth.models import User
from django.db import IntegrityError
from rest_framework_simplejwt.tokens import RefreshToken
from login.models import Medico, Paciente
from login.serializers import MedicoSerializer, PacienteSerializer, UserSerializer

@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    try:
        data = request.data
        
        # Validaciones básicas
        if not data.get('username'):
            return Response({'success': False, 'error': 'El nombre de usuario es requerido'}, status=400)
        
        if not data.get('password1'):
            return Response({'success': False, 'error': 'La contraseña es requerida'}, status=400)
        
        if data.get('password1') != data.get('password2'):
            return Response({'success': False, 'error': 'Las contraseñas no coinciden'}, status=400)

        username = data.get('username')
        password = data.get('password1')
        first_name = data.get('first_name', '')
        last_name = data.get('last_name', '')
        email = data.get('email', '')
        tipo = data.get('tipo_usuario', 'paciente').lower()

        # Crear usuario
        user = User.objects.create_user(username=username, password=password,
                                       first_name=first_name, last_name=last_name, email=email)
        user.save()

        if tipo == 'medico':
            numero_licencia = data.get('numero_licencia', '')
            institucion = data.get('institucion', '')
            ubicacion = data.get('ubicacion_consultorio', '')
            medico = Medico.objects.create(user=user, numero_licencia=numero_licencia,
                                           institucion=institucion, ubicacion_consultorio=ubicacion)
            
            # Generar tokens JWT
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'success': True,
                'tipo_usuario': 'medico',
                'perfil': MedicoSerializer(medico).data,
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }, status=201)
        else:
            fecha_nacimiento = data.get('fecha_nacimiento', None)
            cedula = data.get('cedula', '')
            direccion = data.get('direccion', '')
            telefono = data.get('telefono', '')
            paciente = Paciente.objects.create(user=user, fecha_nacimiento=fecha_nacimiento,
                                               cedula=cedula, direccion=direccion, telefono=telefono)
            
            # Generar tokens JWT
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'success': True,
                'tipo_usuario': 'paciente',
                'perfil': PacienteSerializer(paciente).data,
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }, status=201)
    
    except IntegrityError:
        return Response({'success': False, 'error': 'El usuario ya existe'}, status=400)
    except Exception as e:
        # Captura cualquier otro error y devuelve JSON (no HTML)
        return Response({'success': False, 'error': f'Error en el servidor: {str(e)}'}, status=500)