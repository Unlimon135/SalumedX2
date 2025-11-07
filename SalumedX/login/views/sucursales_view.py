from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from login.models import Sucursal, Farmacia
from login.serializers import SucursalSerializer


@api_view(['GET'])
@permission_classes([AllowAny])
def sucursales(request):
    """
    GET: Devuelve todas las sucursales disponibles.
    Puedes filtrar por:
    - id: /sucursales/?id=1
    - farmacia: /sucursales/?farmacia=2 (id de la farmacia)
    - ubicacion: /sucursales/?ubicacion=Guayaquil
    
    Incluye información completa de la farmacia asociada.
    """
    try:
        queryset = Sucursal.objects.all()
        
        # Filtro por id
        sucursal_id = request.query_params.get('id')
        if sucursal_id:
            try:
                sucursal = Sucursal.objects.get(pk=sucursal_id)
                return Response(SucursalSerializer(sucursal).data)
            except Sucursal.DoesNotExist:
                return Response({'error': 'Sucursal no encontrada'}, status=404)
        
        # Filtro por farmacia
        farmacia_id = request.query_params.get('farmacia')
        if farmacia_id:
            queryset = queryset.filter(farmacia_id=farmacia_id)
        
        # Filtro por ubicación
        ubicacion = request.query_params.get('ubicacion')
        if ubicacion:
            queryset = queryset.filter(ubicacion__icontains=ubicacion)
        
        data = SucursalSerializer(queryset, many=True).data
        return Response({'sucursales': data, 'total': len(data)})
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)
