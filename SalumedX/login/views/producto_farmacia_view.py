from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from login.models import ProductoFarmacia, Producto, Farmacia
from login.serializers import ProductoFarmaciaSerializer


@api_view(['GET'])
@permission_classes([AllowAny])
def producto_farmacia_list(request):
    """
    GET: Lista precios de productos por farmacia. Acepta filtros:
    - producto: ID del producto
    - farmacia: ID de la farmacia
    - nombre: Busca por nombre del producto (comercial o genérico)
    
    Ejemplos:
    /productos-farmacias/
    /productos-farmacias/?producto=5
    /productos-farmacias/?farmacia=2
    /productos-farmacias/?nombre=paracetamol
    /productos-farmacias/?producto=5&farmacia=2
    """
    try:
        queryset = ProductoFarmacia.objects.select_related('producto', 'farmacia').all()
        
        # Filtro por producto
        producto_id = request.query_params.get('producto')
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        
        # Filtro por farmacia
        farmacia_id = request.query_params.get('farmacia')
        if farmacia_id:
            queryset = queryset.filter(farmacia_id=farmacia_id)
        
        # Filtro por nombre de producto (búsqueda en nombre comercial o genérico)
        nombre = request.query_params.get('nombre')
        if nombre:
            queryset = queryset.filter(
                producto__nombre_comercial__icontains=nombre
            ) | queryset.filter(
                producto__nombre_generico__icontains=nombre
            )
        
        # Ordenar por precio (ascendente por defecto)
        orden = request.query_params.get('orden', 'precio')
        if orden == 'precio_desc':
            queryset = queryset.order_by('-precio')
        else:
            queryset = queryset.order_by('precio')
        
        serializer = ProductoFarmaciaSerializer(queryset, many=True)
        
        return Response({
            'success': True,
            'resultados': serializer.data,
            'total': len(serializer.data)
        })
    
    except Exception as e:
        return Response({
            'error': f'Error en el servidor: {str(e)}'
        }, status=500)


@api_view(['GET'])
@permission_classes([AllowAny])
def comparar_precios(request):
    """
    GET: Compara precios de un producto específico en todas las farmacias.
    Requiere: ?producto=<id>
    
    Retorna el producto con la lista de farmacias y sus precios ordenados de menor a mayor.
    """
    try:
        producto_id = request.query_params.get('producto')
        
        if not producto_id:
            return Response({
                'error': 'Se requiere el parámetro "producto"'
            }, status=400)
        
        try:
            producto = Producto.objects.get(pk=producto_id)
        except Producto.DoesNotExist:
            return Response({
                'error': 'Producto no encontrado'
            }, status=404)
        
        # Obtener precios en todas las farmacias
        precios = ProductoFarmacia.objects.filter(
            producto_id=producto_id
        ).select_related('farmacia').order_by('precio')
        
        if not precios.exists():
            return Response({
                'producto': {
                    'id': producto.id_producto,
                    'nombre_comercial': producto.nombre_comercial,
                    'nombre_generico': producto.nombre_generico,
                    'precio_base': str(producto.precio_base)
                },
                'precios_por_farmacia': [],
                'mensaje': 'Este producto aún no tiene precios registrados en farmacias'
            })
        
        precios_data = ProductoFarmaciaSerializer(precios, many=True).data
        
        # Calcular estadísticas
        precios_list = [float(p.precio) for p in precios]
        precio_min = min(precios_list)
        precio_max = max(precios_list)
        precio_promedio = sum(precios_list) / len(precios_list)
        
        return Response({
            'producto': {
                'id': producto.id_producto,
                'nombre_comercial': producto.nombre_comercial,
                'nombre_generico': producto.nombre_generico,
                'precio_base': str(producto.precio_base),
                'presentacion': producto.presentacion,
                'concentracion': producto.concentracion
            },
            'estadisticas': {
                'precio_minimo': precio_min,
                'precio_maximo': precio_max,
                'precio_promedio': round(precio_promedio, 2),
                'diferencia': round(precio_max - precio_min, 2),
                'ahorro_porcentual': round(((precio_max - precio_min) / precio_max * 100), 2) if precio_max > 0 else 0
            },
            'precios_por_farmacia': precios_data,
            'total_farmacias': len(precios_data)
        })
    
    except Exception as e:
        return Response({
            'error': f'Error en el servidor: {str(e)}'
        }, status=500)
