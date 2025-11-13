from django.shortcuts import render
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser, AllowAny
from login.serializers import ProductoSerializer, ProductoFarmaciaSerializer
from login.models import Producto, ProductoFarmacia


def admin_vue(request):
    """Renderiza el template que carga la app Vue (CDN).
    La plantilla hace un fetch a /admin-ui/initial-data/ para bootstrapping.
    """
    return render(request, 'admin_vue.html')


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_initial_data(request):
    """Devuelve datos iniciales que el SPA puede usar para renderizar rápidamente.
    Por ahora devuelve una lista pequeña de productos con sus precios por farmacia.
    """
    productos = Producto.objects.all()[:20]
    productos_data = []
    for p in productos:
        pdata = ProductoSerializer(p).data
        precios = ProductoFarmacia.objects.filter(producto=p).select_related('farmacia')
        pdata['precios_por_farmacia'] = ProductoFarmaciaSerializer(precios, many=True).data
        productos_data.append(pdata)

    return JsonResponse({'productos': productos_data})
