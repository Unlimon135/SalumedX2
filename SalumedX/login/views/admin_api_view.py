"""
Endpoints API para administración.
Estos endpoints están protegidos y requieren que el usuario:
1. Tenga un token JWT válido
2. Sea staff (is_staff=True)

Tu compañero de Vue puede consumir estos endpoints enviando:
Authorization: Bearer <token_jwt>
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from login.models import Producto, ProductoFarmacia, Farmacia
from login.serializers import ProductoSerializer, ProductoFarmaciaSerializer, FarmaciaSerializer


class IsStaff(IsAuthenticated):
    """
    Permiso personalizado: usuario autenticado Y staff.
    """
    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.is_staff


@api_view(['GET', 'POST'])
@permission_classes([IsStaff])
def admin_productos_list(request):
    """
    GET /api/admin/productos/
    Devuelve todos los productos con sus precios (mismo formato que /productos/).
    Requiere: JWT + is_staff=True
    
    Filtros opcionales:
    - ?search=nombre
    - ?categoria=categoria
    - ?con_precios=true
    
    POST /api/admin/productos/
    Crea un nuevo producto.
    Body: {
        "nombre_generico": "Ibuprofeno",
        "nombre_comercial": "Advil",
        "principio_activo": "Ibuprofeno",
        "categoria": "Analgésicos",
        "requiere_receta": false
    }
    """
    if request.method == 'POST':
        try:
            serializer = ProductoSerializer(data=request.data)
            if serializer.is_valid():
                producto = serializer.save()
                return Response({
                    'success': True,
                    'message': 'Producto creado correctamente',
                    'producto': ProductoSerializer(producto).data
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    'success': False,
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    # GET method
    try:
        queryset = Producto.objects.all()
        
        # Filtros
        search = request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(nombre_generico__icontains=search) | 
                Q(nombre_comercial__icontains=search) |
                Q(principio_activo__icontains=search)
            )
        
        categoria = request.query_params.get('categoria')
        if categoria:
            queryset = queryset.filter(categoria__icontains=categoria)
        
        con_precios = request.query_params.get('con_precios')
        if con_precios and con_precios.lower() == 'true':
            queryset = queryset.filter(precios_por_farmacia__isnull=False).distinct()
        
        # Construir respuesta con precios
        productos_data = []
        for producto in queryset:
            producto_dict = ProductoSerializer(producto).data
            precios = ProductoFarmacia.objects.filter(producto=producto).select_related('farmacia')
            producto_dict['precios_por_farmacia'] = ProductoFarmaciaSerializer(precios, many=True).data
            
            if precios.exists():
                precios_list = [float(p.precio) for p in precios]
                producto_dict['precio_minimo'] = min(precios_list)
                producto_dict['precio_maximo'] = max(precios_list)
                producto_dict['precio_promedio'] = round(sum(precios_list) / len(precios_list), 2)
            else:
                producto_dict['precio_minimo'] = None
                producto_dict['precio_maximo'] = None
                producto_dict['precio_promedio'] = None
            
            productos_data.append(producto_dict)
        
        return Response({
            'success': True,
            'productos': productos_data,
            'total': len(productos_data),
            'user': request.user.username  # Para confirmar autenticación
        })
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET', 'POST'])
@permission_classes([IsStaff])
def admin_farmacias_list(request):
    """
    GET /api/admin/farmacias/
    Devuelve todas las farmacias.
    Requiere: JWT + is_staff=True
    
    POST /api/admin/farmacias/
    Crea una nueva farmacia.
    Body: {
        "nombre_comercial": "Farmacia Cruz Azul",
        "direccion": "Calle Principal 123",
        "telefono": "0999999999"
    }
    """
    if request.method == 'POST':
        try:
            serializer = FarmaciaSerializer(data=request.data)
            if serializer.is_valid():
                farmacia = serializer.save()
                return Response({
                    'success': True,
                    'message': 'Farmacia creada correctamente',
                    'farmacia': FarmaciaSerializer(farmacia).data
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    'success': False,
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    # GET method
    try:
        farmacias = Farmacia.objects.all()
        serializer = FarmaciaSerializer(farmacias, many=True)
        return Response({
            'success': True,
            'farmacias': serializer.data,
            'total': farmacias.count()
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET', 'POST'])
@permission_classes([IsStaff])
def admin_producto_farmacia(request):
    """
    GET /api/admin/producto-farmacia/
    Devuelve todas las relaciones producto-farmacia con precios.
    
    POST /api/admin/producto-farmacia/
    Crea o actualiza un precio de producto en farmacia.
    Body: {
        "producto": 1,
        "farmacia": 2,
        "precio": "15.50",
        "disponible": true
    }
    
    Requiere: JWT + is_staff=True
    """
    if request.method == 'GET':
        try:
            # Filtros opcionales
            producto_id = request.query_params.get('producto')
            farmacia_id = request.query_params.get('farmacia')
            
            queryset = ProductoFarmacia.objects.all().select_related('producto', 'farmacia')
            
            if producto_id:
                queryset = queryset.filter(producto_id=producto_id)
            if farmacia_id:
                queryset = queryset.filter(farmacia_id=farmacia_id)
            
            serializer = ProductoFarmaciaSerializer(queryset, many=True)
            return Response({
                'success': True,
                'precios': serializer.data,
                'total': queryset.count()
            })
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    elif request.method == 'POST':
        try:
            producto_id = request.data.get('producto')
            farmacia_id = request.data.get('farmacia')
            precio = request.data.get('precio')
            disponible = request.data.get('disponible', True)
            
            if not all([producto_id, farmacia_id, precio]):
                return Response({
                    'error': 'Faltan campos requeridos: producto, farmacia, precio'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Validar que existan
            try:
                producto = Producto.objects.get(pk=producto_id)
                farmacia = Farmacia.objects.get(pk=farmacia_id)
            except Producto.DoesNotExist:
                return Response({'error': 'Producto no encontrado'}, status=status.HTTP_404_NOT_FOUND)
            except Farmacia.DoesNotExist:
                return Response({'error': 'Farmacia no encontrada'}, status=status.HTTP_404_NOT_FOUND)
            
            # Crear o actualizar
            producto_farmacia, created = ProductoFarmacia.objects.update_or_create(
                producto=producto,
                farmacia=farmacia,
                defaults={
                    'precio': precio,
                    'disponible': disponible
                }
            )
            
            serializer = ProductoFarmaciaSerializer(producto_farmacia)
            return Response({
                'success': True,
                'created': created,
                'producto_farmacia': serializer.data
            }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
        
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsStaff])
def admin_producto_farmacia_delete(request, pk):
    """
    DELETE /api/admin/producto-farmacia/<id>/
    
    Elimina una relación producto-farmacia (precio).
    Requiere: JWT + is_staff=True
    """
    try:
        producto_farmacia = ProductoFarmacia.objects.get(pk=pk)
        producto_farmacia.delete()
        return Response({
            'success': True,
            'message': f'Precio eliminado correctamente'
        }, status=status.HTTP_200_OK)
    except ProductoFarmacia.DoesNotExist:
        return Response({'error': 'Precio no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsStaff])
def admin_stats(request):
    """
    GET /api/admin/stats/
    
    Estadísticas generales del sistema.
    Requiere: JWT + is_staff=True
    """
    try:
        from login.models import Paciente, Medico, Receta
        
        stats = {
            'productos': Producto.objects.count(),
            'farmacias': Farmacia.objects.count(),
            'precios_registrados': ProductoFarmacia.objects.count(),
            'productos_sin_precio': Producto.objects.filter(precios_por_farmacia__isnull=True).count(),
            'pacientes': Paciente.objects.count(),
            'medicos': Medico.objects.count(),
            'recetas': Receta.objects.count()
        }
        
        return Response({
            'success': True,
            'stats': stats
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([])  # Sin autenticación - endpoint público
def admin_health_check(request):
    """
    GET /api/admin/health/
    
    Endpoint de prueba para verificar que la API admin está funcionando.
    No requiere autenticación.
    """
    return Response({
        'success': True,
        'message': 'Admin API is working!',
        'endpoints': [
            'GET/POST /api/admin/productos/',
            'GET/POST /api/admin/farmacias/',
            'GET/POST /api/admin/producto-farmacia/',
            'DELETE /api/admin/producto-farmacia/<id>/',
            'GET /api/admin/stats/',
        ]
    }, status=status.HTTP_200_OK)
