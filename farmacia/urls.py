from django.urls import path
from farmacia import views

urlpatterns = [
    # Productos
    path('productos/', views.productos_list_create, name='productos-list-create'),
    path('productos/<int:pk>/', views.producto_detail, name='producto-detail'),
    
    # Ventas
    path('ventas/', views.ventas_list_create, name='ventas-list-create'),
    path('ventas/<int:pk>/', views.venta_detail, name='venta-detail'),
]
