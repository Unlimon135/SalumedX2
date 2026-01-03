from django.contrib import admin
from .models import Producto, Venta, DetalleVenta


@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ['id_producto', 'nombre_comercial', 'nombre_generico', 'stock', 'precio']
    search_fields = ['nombre_comercial', 'nombre_generico', 'principio_activo']


@admin.register(Venta)
class VentaAdmin(admin.ModelAdmin):
    list_display = ['id_venta', 'cliente', 'farmaceutico', 'total', 'created_at']
    list_filter = ['created_at']


@admin.register(DetalleVenta)
class DetalleVentaAdmin(admin.ModelAdmin):
    list_display = ['id_detalle', 'venta', 'producto', 'cantidad', 'precio_unitario', 'subtotal']
