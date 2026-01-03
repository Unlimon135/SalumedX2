from rest_framework import serializers
from farmacia.models import Producto, Venta, DetalleVenta


class ProductoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Producto
        fields = ['id_producto', 'nombre_generico', 'nombre_comercial', 
                  'principio_activo', 'categoria', 'presentacion', 'concentracion',
                  'stock', 'precio', 'created_at', 'updated_at']
        read_only_fields = ['id_producto', 'created_at', 'updated_at']


class ProductoListSerializer(serializers.ModelSerializer):
    """Serializer para clientes - oculta el stock"""
    class Meta:
        model = Producto
        fields = ['id_producto', 'nombre_generico', 'nombre_comercial', 
                  'principio_activo', 'categoria', 'presentacion', 'concentracion',
                  'precio']


class DetalleVentaSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre_comercial', read_only=True)
    
    class Meta:
        model = DetalleVenta
        fields = ['id_detalle', 'producto', 'producto_nombre', 'cantidad', 
                  'precio_unitario', 'subtotal']
        read_only_fields = ['id_detalle', 'precio_unitario', 'subtotal']


class VentaSerializer(serializers.ModelSerializer):
    detalles = DetalleVentaSerializer(many=True)
    cliente_nombre = serializers.CharField(source='cliente.username', read_only=True)
    farmaceutico_nombre = serializers.CharField(source='farmaceutico.username', read_only=True)

    class Meta:
        model = Venta
        fields = ['id_venta', 'cliente', 'cliente_nombre', 'farmaceutico', 
                  'farmaceutico_nombre', 'total', 'detalles', 'created_at']
        read_only_fields = ['id_venta', 'total', 'created_at']

    def create(self, validated_data):
        detalles_data = validated_data.pop('detalles')
        
        # Calcular total
        total = 0
        for detalle in detalles_data:
            producto = detalle['producto']
            cantidad = detalle['cantidad']
            
            # Verificar stock
            if producto.stock < cantidad:
                raise serializers.ValidationError(
                    f"Stock insuficiente para {producto.nombre_comercial}"
                )
            
            precio_unitario = producto.precio
            subtotal = precio_unitario * cantidad
            total += subtotal
            
            detalle['precio_unitario'] = precio_unitario
            detalle['subtotal'] = subtotal

        # Crear venta
        venta = Venta.objects.create(total=total, **validated_data)

        # Crear detalles y actualizar stock
        for detalle_data in detalles_data:
            DetalleVenta.objects.create(venta=venta, **detalle_data)
            producto = detalle_data['producto']
            producto.stock -= detalle_data['cantidad']
            producto.save()

        return venta


class VentaListSerializer(serializers.ModelSerializer):
    cliente_nombre = serializers.CharField(source='cliente.username', read_only=True)
    farmaceutico_nombre = serializers.CharField(source='farmaceutico.username', read_only=True)
    
    class Meta:
        model = Venta
        fields = ['id_venta', 'cliente_nombre', 'farmaceutico_nombre', 'total', 'created_at']
