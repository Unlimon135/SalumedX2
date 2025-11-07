from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from login.models import DetallePrescripcion, DetalleReceta, Farmacia, Producto
from login.serializers import DetallePrescripcionSerializer


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])  # Puedes cambiar a IsAuthenticated si requieres autenticación
def detalle_prescripcion(request):
    """
    GET: devuelve detalles de prescripción según el usuario autenticado:
         - Médicos: solo prescripciones de recetas que ellos emitieron
         - Pacientes: solo prescripciones de sus propias recetas
         - No autenticados: sin acceso (devuelve error 401)
         
         Puedes filtrar adicionalmente por farmacia, producto o detalle_receta usando query params.
         Ejemplo: /detalle-prescripcion/?farmacia=1&producto=5
    
    POST: crea un nuevo detalle de prescripción. Formato esperado (JSON):
    {
      "detalle_receta": <id_detalle_receta>,
      "farmacia": <id_farmacia>,
      "producto": <id_producto>,
      "precio_encontrado": 12.50,
      "distancia": 2.5,
      "fuente": "Página web oficial"
    }
    """
    
    try:
        # GET: listar detalles de prescripción con filtros de seguridad
        if request.method == 'GET':
            # Validar que el usuario esté autenticado
            if not request.user.is_authenticated:
                return Response({
                    'error': 'Debe autenticarse para consultar prescripciones.'
                }, status=401)
            
            user = request.user
            queryset = DetallePrescripcion.objects.all()
            
            # Filtrar según tipo de usuario
            if hasattr(user, 'medico'):
                # Médico: solo prescripciones de recetas que él emitió
                queryset = queryset.filter(detalle_receta__receta__medico=user.medico)
            elif hasattr(user, 'paciente'):
                # Paciente: solo prescripciones de sus propias recetas
                queryset = queryset.filter(detalle_receta__receta__paciente=user.paciente)
            else:
                # Usuario sin perfil de médico o paciente: sin acceso
                return Response({
                    'error': 'No tiene permiso para consultar prescripciones.'
                }, status=403)
            
            # Filtros opcionales vía query params (adicionales a la seguridad)
            farmacia_id = request.query_params.get('farmacia')
            producto_id = request.query_params.get('producto')
            detalle_receta_id = request.query_params.get('detalle_receta')
            
            if farmacia_id:
                queryset = queryset.filter(farmacia_id=farmacia_id)
            if producto_id:
                queryset = queryset.filter(producto_id=producto_id)
            if detalle_receta_id:
                queryset = queryset.filter(detalle_receta_id=detalle_receta_id)
            
            data = DetallePrescripcionSerializer(queryset, many=True).data
            return Response({'detalle_prescripciones': data, 'total': len(data)})
        
        # POST: crear detalle de prescripción
        payload = request.data
        detalle_receta_id = payload.get('detalle_receta')
        farmacia_id = payload.get('farmacia')
        producto_id = payload.get('producto')
        
        # Validar campos obligatorios
        if not all([detalle_receta_id, farmacia_id, producto_id]):
            return Response({
                'error': 'Se requieren los campos: detalle_receta, farmacia, producto'
            }, status=400)
        
        # Validar existencia de objetos relacionados
        try:
            detalle_receta = DetalleReceta.objects.get(pk=detalle_receta_id)
        except DetalleReceta.DoesNotExist:
            return Response({'error': 'Detalle de receta no encontrado.'}, status=404)
        
        try:
            farmacia = Farmacia.objects.get(pk=farmacia_id)
        except Farmacia.DoesNotExist:
            return Response({'error': 'Farmacia no encontrada.'}, status=404)
        
        try:
            producto = Producto.objects.get(pk=producto_id)
        except Producto.DoesNotExist:
            return Response({'error': 'Producto no encontrado.'}, status=404)
        
        # Crear el detalle de prescripción
        detalle_prescripcion = DetallePrescripcion.objects.create(
            detalle_receta=detalle_receta,
            farmacia=farmacia,
            producto=producto,
            precio_encontrado=payload.get('precio_encontrado', 0),
            distancia=payload.get('distancia', 0),
            fuente=payload.get('fuente', '')
        )
        
        result = DetallePrescripcionSerializer(detalle_prescripcion).data
        return Response({'success': True, 'detalle_prescripcion': result})
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)