from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from login.models import Producto, ProductoFarmacia
from login.serializers import ProductoSerializer, ProductoFarmaciaSerializer
from django.db.models import Q


@api_view(['GET'])
@permission_classes([AllowAny])
def productos(request):
    """
    GET: Devuelve todos los productos con sus precios por farmacia.
    Puedes filtrar por:
    - id: /productos/?id=1
    - categoria: /productos/?categoria=Analgésicos
    - requiere_receta: /productos/?requiere_receta=true
    - search: /productos/?search=paracetamol (busca en nombre_generico, nombre_comercial, principio_activo)
    - con_precios: /productos/?con_precios=true (solo productos con precios en farmacias)
    """
    try:
        queryset = Producto.objects.all()
        
        # Filtro por id específico
        producto_id = request.query_params.get('id')
        if producto_id:
            try:
                producto = Producto.objects.get(pk=producto_id)
                producto_dict = ProductoSerializer(producto).data
                
                # Agregar precios por farmacia
                precios = ProductoFarmacia.objects.filter(
                    producto=producto
                ).select_related('farmacia')
                
                producto_dict['precios_por_farmacia'] = ProductoFarmaciaSerializer(
                    precios, many=True
                ).data
                
                # Estadísticas de precio
                if precios.exists():
                    precios_list = [float(p.precio) for p in precios]
                    producto_dict['precio_minimo'] = min(precios_list)
                    producto_dict['precio_maximo'] = max(precios_list)
                    producto_dict['precio_promedio'] = round(sum(precios_list) / len(precios_list), 2)
                else:
                    producto_dict['precio_minimo'] = None
                    producto_dict['precio_maximo'] = None
                    producto_dict['precio_promedio'] = None
                
                return Response(producto_dict)
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
            queryset = queryset.filter(
                Q(nombre_generico__icontains=search) | 
                Q(nombre_comercial__icontains=search) |
                Q(principio_activo__icontains=search)
            )
        
        # Filtro: solo productos con precios
        con_precios = request.query_params.get('con_precios')
        if con_precios and con_precios.lower() == 'true':
            queryset = queryset.filter(precios_por_farmacia__isnull=False).distinct()
        
        # Construir respuesta con precios
        productos_data = []
        for producto in queryset:
            producto_dict = ProductoSerializer(producto).data
            
            # Agregar precios por farmacia
            precios = ProductoFarmacia.objects.filter(
                producto=producto
            ).select_related('farmacia')
            
            producto_dict['precios_por_farmacia'] = ProductoFarmaciaSerializer(
                precios, many=True
            ).data
            
            # Estadísticas de precio
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
            'total': len(productos_data)
        })
    
    except Exception as e:
        return Response({'error': f'Error en el servidor: {str(e)}'}, status=500)
