from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from login.models import Farmacia
from login.serializers import FarmaciaSerializer


@api_view(['GET'])
@permission_classes([AllowAny])
def farmacias(request):
    """
    GET: Devuelve todas las farmacias disponibles.
    Puedes filtrar por:
    - id: /farmacias/?id=1
    - search: /farmacias/?search=cruz (busca en nombre_comercial)
    """
    try:
        queryset = Farmacia.objects.all()
        
        # Filtro por id
        farmacia_id = request.query_params.get('id')
        if farmacia_id:
            try:
                farmacia = Farmacia.objects.get(pk=farmacia_id)
                return Response(FarmaciaSerializer(farmacia).data)
            except Farmacia.DoesNotExist:
                return Response({'error': 'Farmacia no encontrada'}, status=404)
        
        # Búsqueda por nombre
        search = request.query_params.get('search')
        if search:
            queryset = queryset.filter(nombre_comercial__icontains=search)
        
        data = FarmaciaSerializer(queryset, many=True).data
        return Response({'farmacias': data, 'total': len(data)})
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)
