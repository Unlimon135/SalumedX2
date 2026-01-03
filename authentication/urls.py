from django.urls import path
from authentication import views

urlpatterns = [
    path('register/', views.register_view, name='register'),
    path('register-cliente/', views.register_cliente_view, name='register-cliente'),
    path('login/', views.login_view, name='login'),
    path('me/', views.me_view, name='me'),
]
