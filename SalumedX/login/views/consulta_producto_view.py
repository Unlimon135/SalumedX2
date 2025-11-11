from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from login.models import ConsultaProducto, Producto, Farmacia, ProductoFarmacia
from login.serializers import ConsultaProductoSerializer


@api_view(['POST'])
@permission_classes([AllowAny])
def registrar_consulta(request):
    """
    POST: Registra una consulta de producto.
    
    Puede ser:
    - Usuario autenticado (se guarda el user)
    - Usuario anónimo (user=None)
    
    Body esperado:
    {
      "producto_id": 5,
      "farmacia_id": 2,  // opcional
      "producto_farmacia_id": 10,  // opcional
      "precio_visto": "3.50",
      "origen": "public_search"  // public_search, user_interest, saved, comparison
    }
    """
    try:
        data = request.data.copy()
        
        # Validar producto existe
        producto_id = data.get('producto_id')
        if not producto_id:
            return Response({'error': 'Se requiere producto_id'}, status=400)
        
        try:
            producto = Producto.objects.get(pk=producto_id)
        except Producto.DoesNotExist:
            return Response({'error': 'Producto no encontrado'}, status=404)
        
        # Validar farmacia si se proporciona
        farmacia_id = data.get('farmacia_id')
        if farmacia_id:
            try:
                Farmacia.objects.get(pk=farmacia_id)
            except Farmacia.DoesNotExist:
                return Response({'error': 'Farmacia no encontrada'}, status=404)
        
        # Validar producto_farmacia si se proporciona
        producto_farmacia_id = data.get('producto_farmacia_id')
        if producto_farmacia_id:
            try:
                ProductoFarmacia.objects.get(pk=producto_farmacia_id)
            except ProductoFarmacia.DoesNotExist:
                return Response({'error': 'ProductoFarmacia no encontrado'}, status=404)
        
        # Crear consulta
        consulta = ConsultaProducto.objects.create(
            user=request.user if request.user.is_authenticated else None,
            producto_id=producto_id,
            farmacia_id=farmacia_id if farmacia_id else None,
            producto_farmacia_id=producto_farmacia_id if producto_farmacia_id else None,
            precio_visto=data.get('precio_visto'),
            origen=data.get('origen', 'public_search')
        )
        
        serializer = ConsultaProductoSerializer(consulta)
        return Response({
            'success': True,
            'consulta': serializer.data,
            'mensaje': 'Consulta registrada exitosamente'
        }, status=201)
    
    except Exception as e:
        return Response({
            'error': f'Error en el servidor: {str(e)}'
        }, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def historial_consultas(request):
    """
    GET: Obtiene el historial de consultas del usuario autenticado.
    
    Filtros opcionales:
    - ?producto=<id> - Filtrar por producto
    - ?farmacia=<id> - Filtrar por farmacia
    - ?origen=<tipo> - Filtrar por origen
    - ?limit=<n> - Limitar resultados (default: 50)
    """
    try:
        user = request.user
        
        # Consultas del usuario
        queryset = ConsultaProducto.objects.filter(user=user).select_related(
            'producto', 'farmacia', 'producto_farmacia'
        )
        
        # Filtros
        producto_id = request.query_params.get('producto')
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        
        farmacia_id = request.query_params.get('farmacia')
        if farmacia_id:
            queryset = queryset.filter(farmacia_id=farmacia_id)
        
        origen = request.query_params.get('origen')
        if origen:
            queryset = queryset.filter(origen=origen)
        
        # Limitar resultados
        limit = int(request.query_params.get('limit', 50))
        queryset = queryset[:limit]
        
        serializer = ConsultaProductoSerializer(queryset, many=True)
        
        return Response({
            'success': True,
            'consultas': serializer.data,
            'total': len(serializer.data)
        })
    
    except Exception as e:
        return Response({
            'error': f'Error en el servidor: {str(e)}'
        }, status=500)


@api_view(['GET'])
@permission_classes([AllowAny])
def estadisticas_consultas(request):
    """
    GET: Obtiene estadísticas públicas de consultas.
    
    Retorna:
    - Productos más consultados
    - Farmacias más consultadas
    - Total de consultas
    """
    try:
        from django.db.models import Count
        
        # Productos más consultados (top 10)
        productos_top = ConsultaProducto.objects.values(
            'producto__id_producto',
            'producto__nombre_comercial',
            'producto__nombre_generico'
        ).annotate(
            total_consultas=Count('id_consulta')
        ).order_by('-total_consultas')[:10]
        
        # Farmacias más consultadas (top 10)
        farmacias_top = ConsultaProducto.objects.filter(
            farmacia__isnull=False
        ).values(
            'farmacia__id_farmacia',
            'farmacia__nombre_comercial'
        ).annotate(
            total_consultas=Count('id_consulta')
        ).order_by('-total_consultas')[:10]
        
        # Total de consultas
        total_consultas = ConsultaProducto.objects.count()
        
        return Response({
            'success': True,
            'estadisticas': {
                'total_consultas': total_consultas,
                'productos_mas_consultados': list(productos_top),
                'farmacias_mas_consultadas': list(farmacias_top)
            }
        })
    
    except Exception as e:
        return Response({
            'error': f'Error en el servidor: {str(e)}'
        }, status=500)
