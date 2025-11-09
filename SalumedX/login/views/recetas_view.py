from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from login.models import Receta, Medico, Paciente, Producto, DetalleReceta
from login.serializers import RecetaSerializer
from datetime import date


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def recetas(request):
    """
    GET: devuelve las recetas del médico autenticado O del paciente autenticado.
    - Médicos: ven las recetas que ellos escribieron
    - Pacientes: ven las recetas que les escribieron
    
    POST: crea una receta (solo para médicos). Formato esperado (JSON):
    {
      "paciente": <id_paciente>,
      "fecha_emision": "YYYY-MM-DD", (opcional, por defecto hoy)
      "diagnostico": "...",
      "observaciones": "...",
      "ubicacion_emision": "...",
      "detalles": [
         { "producto": <id_producto>, "cantidad": 1, "dosis": "...", "presentacion": "...", "duracion_tratamiento": "...", "instrucciones": "..." },
         ...
      ]
    }
    """
    try:
        user = request.user

        # GET: listar recetas según tipo de usuario
        if request.method == 'GET':
            # Determinar si es médico o paciente
            if hasattr(user, 'medico'):
                # Médico: ver las recetas que él escribió
                recetas_qs = Receta.objects.filter(medico=user.medico)
            elif hasattr(user, 'paciente'):
                # Paciente: ver las recetas que le escribieron
                recetas_qs = Receta.objects.filter(paciente=user.paciente)
            else:
                return Response({'error': 'Usuario sin perfil de médico o paciente'}, status=403)
            
            # Filtro por ID de receta específica
            receta_id = request.query_params.get('id')
            if receta_id:
                try:
                    receta = recetas_qs.get(pk=receta_id)
                    return Response({'receta': RecetaSerializer(receta).data})
                except Receta.DoesNotExist:
                    return Response({'error': 'Receta no encontrada o no tienes permiso para verla'}, status=404)
            
            # Filtro por paciente (solo para médicos)
            paciente_id = request.query_params.get('paciente')
            if paciente_id and hasattr(user, 'medico'):
                recetas_qs = recetas_qs.filter(paciente_id=paciente_id)
            
            # Filtro por fecha
            fecha = request.query_params.get('fecha')
            if fecha:
                recetas_qs = recetas_qs.filter(fecha_emision=fecha)
            
            data = RecetaSerializer(recetas_qs, many=True).data
            return Response({'recetas': data, 'total': len(data)})

        # POST: crear receta (solo médicos)
        if not hasattr(user, 'medico'):
            return Response({'error': 'Solo los médicos pueden crear recetas.'}, status=403)
        payload = request.data
        paciente_id = payload.get('paciente') or payload.get('paciente_id')
        if not paciente_id:
            return Response({'error': 'Se requiere el id del paciente (campo "paciente").'}, status=400)

        try:
            paciente = Paciente.objects.get(pk=paciente_id)
        except Paciente.DoesNotExist:
            return Response({'error': 'Paciente no encontrado.'}, status=404)

        fecha_emision = payload.get('fecha_emision') or date.today().isoformat()
        diagnostico = payload.get('diagnostico', '')
        observaciones = payload.get('observaciones', '')
        ubicacion_emision = payload.get('ubicacion_emision', '')

        receta = Receta.objects.create(
            medico=user.medico,
            paciente=paciente,
            fecha_emision=fecha_emision,
            diagnostico=diagnostico,
            observaciones=observaciones,
            ubicacion_emision=ubicacion_emision
        )

        detalles = payload.get('detalles', [])
        for d in detalles:
            producto_id = d.get('producto') or d.get('producto_id')
            if not producto_id:
                continue
            try:
                producto = Producto.objects.get(pk=producto_id)
            except Producto.DoesNotExist:
                continue

            DetalleReceta.objects.create(
                receta=receta,
                producto=producto,
                cantidad=d.get('cantidad', 1),
                dosis=d.get('dosis', ''),
                presentacion=d.get('presentacion', ''),
                duracion_tratamiento=d.get('duracion_tratamiento', ''),
                instrucciones=d.get('instrucciones', '')
            )

        receta.refresh_from_db()
        result = RecetaSerializer(receta).data
        return Response({'success': True, 'receta': result})
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)