from django.contrib import admin
from .models import Producto, Farmacia, Sucursal, ProductoFarmacia, Medico, Paciente, Receta, DetalleReceta, DetallePrescripcion

# Register your models here.

# Configuración mejorada para ProductoFarmacia
@admin.register(ProductoFarmacia)
class ProductoFarmaciaAdmin(admin.ModelAdmin):
    list_display = ('producto', 'farmacia', 'precio', 'fecha_actualizacion')
    list_filter = ('farmacia', 'producto__categoria', 'fecha_actualizacion')
    search_fields = ('producto__nombre_comercial', 'producto__nombre_generico', 'farmacia__nombre_comercial')
    ordering = ('farmacia', 'producto')
    readonly_fields = ('fecha_actualizacion',)
    
    fieldsets = (
        ('Información del Producto', {
            'fields': ('producto', 'farmacia')
        }),
        ('Precio', {
            'fields': ('precio',)
        }),
        ('Metadata', {
            'fields': ('fecha_actualizacion',),
            'classes': ('collapse',)
        }),
    )

# Configuración mejorada para Producto
@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ('nombre_comercial', 'nombre_generico', 'categoria', 'requiere_receta')
    list_filter = ('categoria', 'requiere_receta')
    search_fields = ('nombre_comercial', 'nombre_generico', 'principio_activo')
    ordering = ('nombre_comercial',)

# Configuración para Farmacia
@admin.register(Farmacia)
class FarmaciaAdmin(admin.ModelAdmin):
    list_display = ('nombre_comercial', 'horario_atencion')
    search_fields = ('nombre_comercial',)

# Configuración para Sucursal
@admin.register(Sucursal)
class SucursalAdmin(admin.ModelAdmin):
    list_display = ('farmacia', 'ubicacion', 'latitud', 'longitud')
    list_filter = ('farmacia',)
    search_fields = ('ubicacion', 'farmacia__nombre_comercial')

# Registrar otros modelos
admin.site.register(Medico)
admin.site.register(Paciente)
admin.site.register(Receta)
admin.site.register(DetalleReceta)
admin.site.register(DetallePrescripcion)
