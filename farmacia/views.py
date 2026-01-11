from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.conf import settings

from farmacia.models import Producto, Venta
from farmacia.serializers import (
    ProductoSerializer,
    ProductoListSerializer,
    VentaSerializer,
    VentaListSerializer
)


def es_farmaceutico(user):
    """Verificar si el usuario es farmaceutico"""
    return user.tipo_usuario == 'farmaceutico'


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def productos_list_create(request):
    """
    GET /api/productos/ - Listar productos
    POST /api/productos/ - Crear producto (solo farmaceutico)
    """
    if request.method == 'GET':
        productos = Producto.objects.all()
        
        # Si es cliente, ocultar el stock
        if request.user.tipo_usuario == 'cliente':
            serializer = ProductoListSerializer(productos, many=True)
        else:
            serializer = ProductoSerializer(productos, many=True)
        
        return Response(serializer.data)

    elif request.method == 'POST':
        # Solo farmaceuticos pueden crear productos
        if not es_farmaceutico(request.user):
            return Response(
                {'error': 'Solo los farmaceuticos pueden crear productos'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = ProductoSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def producto_detail(request, pk):
    """
    GET /api/productos/{id}/ - Ver detalle de producto
    PUT /api/productos/{id}/ - Actualizar producto (solo farmaceutico)
    DELETE /api/productos/{id}/ - Eliminar producto (solo farmaceutico)
    """
    producto = get_object_or_404(Producto, pk=pk)

    if request.method == 'GET':
        if request.user.tipo_usuario == 'cliente':
            serializer = ProductoListSerializer(producto)
        else:
            serializer = ProductoSerializer(producto)
        return Response(serializer.data)

    elif request.method == 'PUT':
        if not es_farmaceutico(request.user):
            return Response(
                {'error': 'Solo los farmaceuticos pueden actualizar productos'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = ProductoSerializer(producto, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        if not es_farmaceutico(request.user):
            return Response(
                {'error': 'Solo los farmaceuticos pueden eliminar productos'},
                status=status.HTTP_403_FORBIDDEN
            )

        producto.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def ventas_list_create(request):
    """
    GET /api/ventas/ - Listar ventas
    POST /api/ventas/ - Crear venta (solo farmaceutico)
    """
    if request.method == 'GET':
        if es_farmaceutico(request.user):
            # Farmaceuticos ven todas las ventas
            ventas = Venta.objects.all()
        else:
            # Clientes solo ven sus propias compras
            ventas = Venta.objects.filter(cliente=request.user)
        
        serializer = VentaListSerializer(ventas, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if not es_farmaceutico(request.user):
            return Response(
                {'error': 'Solo los farmaceuticos pueden realizar ventas'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Agregar el farmaceutico que realiza la venta
        data = request.data.copy()
        data['farmaceutico'] = request.user.id

        serializer = VentaSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def venta_detail(request, pk):
    """
    GET /api/ventas/{id}/ - Ver detalle de venta
    """
    if es_farmaceutico(request.user):
        venta = get_object_or_404(Venta, pk=pk)
    else:
        # Clientes solo pueden ver sus propias compras
        venta = get_object_or_404(Venta, pk=pk, cliente=request.user)

    serializer = VentaSerializer(venta)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([AllowAny])
def confirmar_pago(request):
    """PILAR 2 - Stripe Payment Confirmation: endpoint interno de confirmacion de pagos."""

    provided_secret = request.headers.get('X-INTERNAL-SECRET')
    expected_secret = getattr(settings, 'INTERNAL_SECRET', None)

    if not expected_secret or provided_secret != expected_secret:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    payment_intent_id = request.data.get('paymentIntentId')
    reference = request.data.get('reference')
    amount = request.data.get('amount')

    if not payment_intent_id:
        return Response({'error': 'paymentIntentId is required'}, status=status.HTTP_400_BAD_REQUEST)

    # PILAR 2 - Stripe Payment Confirmation
    return Response(
        {
            'message': 'PILAR 2 - Stripe Payment Confirmation: pago confirmado',
            'payment_intent_id': payment_intent_id,
            'reference': reference,
            'amount': amount,
        },
        status=status.HTTP_200_OK,
    )
