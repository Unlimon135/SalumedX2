from django.contrib import admin
from .models import Producto, Farmacia, Sucursal

# Register your models here.
admin.site.register(Producto)
admin.site.register(Farmacia)
admin.site.register(Sucursal)
