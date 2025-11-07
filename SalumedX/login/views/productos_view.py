from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from login.models import Producto
from login.serializers import ProductoSerializer


@api_view(['GET'])
@permission_classes([AllowAny])
def productos(request):
    """
    GET: Devuelve todos los productos disponibles.
    Puedes filtrar por:
    - id: /productos/?id=1
    - categoria: /productos/?categoria=Analgésicos
    - requiere_receta: /productos/?requiere_receta=true
    - search: /productos/?search=paracetamol (busca en nombre_generico y nombre_comercial)
    """
    try:
        queryset = Producto.objects.all()
        
        # Filtro por id
        producto_id = request.query_params.get('id')
        if producto_id:
            try:
                producto = Producto.objects.get(pk=producto_id)
                return Response(ProductoSerializer(producto).data)
            except Producto.DoesNotExist:
                return Response({'error': 'Producto no encontrado'}, status=404)
        
        # Filtro por categoría
        categoria = request.query_params.get('categoria')
        if categoria:
            queryset = queryset.filter(categoria__icontains=categoria)
        
        # Filtro por requiere_receta
        requiere_receta = request.query_params.get('requiere_receta')
        if requiere_receta:
            requiere = requiere_receta.lower() in ['true', '1', 'yes']
            queryset = queryset.filter(requiere_receta=requiere)
        
        # Búsqueda por nombre
        search = request.query_params.get('search')
        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(nombre_generico__icontains=search) | 
                Q(nombre_comercial__icontains=search) |
                Q(principio_activo__icontains=search)
            )
        
        data = ProductoSerializer(queryset, many=True).data
        return Response({'productos': data, 'total': len(data)})
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)
