from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from login.models import Paciente, Medico
from django.contrib.auth.models import User


@api_view(['GET'])
@permission_classes([AllowAny])
def paciente_info(request):
    """
    GET: Devuelve información de todos los pacientes y sus usuarios asociados.
    Puedes filtrar por id: /paciente-info/?id=2
    """
    try:
        paciente_id = request.query_params.get('id')
        
        if paciente_id:
            try:
                paciente = Paciente.objects.get(pk=paciente_id)
                return Response({
                    'paciente_id': paciente.id,
                    'user_id': paciente.user.id,
                    'username': paciente.user.username,
                    'nombre_completo': paciente.user.get_full_name(),
                    'email': paciente.user.email,
                    'cedula': paciente.cedula,
                    'telefono': paciente.telefono
                })
            except Paciente.DoesNotExist:
                return Response({'error': 'Paciente no encontrado'}, status=404)
        
        # Sin filtro: listar todos los pacientes
        pacientes = Paciente.objects.all()
        data = []
        for p in pacientes:
            data.append({
                'paciente_id': p.id,
                'user_id': p.user.id,
                'username': p.user.username,
                'nombre_completo': p.user.get_full_name(),
                'email': p.user.email,
                'cedula': p.cedula
            })
        
        return Response({'pacientes': data, 'total': len(data)})
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)


@api_view(['GET'])
@permission_classes([AllowAny])
def medico_info(request):
    """
    GET: Devuelve información de todos los médicos y sus usuarios asociados.
    Puedes filtrar por id: /medico-info/?id=1
    """
    try:
        medico_id = request.query_params.get('id')
        
        if medico_id:
            try:
                medico = Medico.objects.get(pk=medico_id)
                return Response({
                    'medico_id': medico.id,
                    'user_id': medico.user.id,
                    'username': medico.user.username,
                    'nombre_completo': medico.user.get_full_name(),
                    'email': medico.user.email,
                    'numero_licencia': medico.numero_licencia,
                    'institucion': medico.institucion
                })
            except Medico.DoesNotExist:
                return Response({'error': 'Médico no encontrado'}, status=404)
        
        # Sin filtro: listar todos los médicos
        medicos = Medico.objects.all()
        data = []
        for m in medicos:
            data.append({
                'medico_id': m.id,
                'user_id': m.user.id,
                'username': m.user.username,
                'nombre_completo': m.user.get_full_name(),
                'email': m.user.email,
                'numero_licencia': m.numero_licencia
            })
        
        return Response({'medicos': data, 'total': len(data)})
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)
