"""
URL configuration for salumedx_rest project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""


from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenRefreshView
from login.views import (
    home, signup, tasks, signout, signin, recetas, 
    detalle_prescripcion, paciente_info, medico_info,
    productos, farmacias, sucursales
)
from login.views.producto_farmacia_view import producto_farmacia_list, comparar_precios

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
    path('signup/', signup, name='signup'),
    path('tasks/', tasks, name='tasks'),
    path('logout/', signout, name='logout'),
    path('signin/', signin, name='signin'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),  # Refrescar JWT
    path('recetas/', recetas, name='recetas'),
    path('detalle-prescripcion/', detalle_prescripcion, name='detalle_prescripcion'),
    path('paciente-info/', paciente_info, name='paciente_info'),
    path('medico-info/', medico_info, name='medico_info'),
    path('productos/', productos, name='productos'),
    path('farmacias/', farmacias, name='farmacias'),
    path('sucursales/', sucursales, name='sucursales'),
    path('productos-farmacias/', producto_farmacia_list, name='producto_farmacia_list'),
    path('comparar-precios/', comparar_precios, name='comparar_precios'),
    # DRF browsable API login (optional)
    path('api-auth/', include('rest_framework.urls'))
]
