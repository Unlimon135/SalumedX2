from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from login.models import Medico, Paciente
from login.serializers import MedicoSerializer, PacienteSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tasks(request):
    try:
        user = request.user
        if hasattr(user, 'medico'):
            return Response({'tipo_usuario': 'medico', 'perfil': MedicoSerializer(user.medico).data})
        elif hasattr(user, 'paciente'):
            return Response({'tipo_usuario': 'paciente', 'perfil': PacienteSerializer(user.paciente).data})
        else:
            return Response({'tipo_usuario': 'desconocido'})
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)