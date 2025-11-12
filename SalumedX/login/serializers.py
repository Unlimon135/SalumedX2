# Serializers para todos los modelos de login
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
	Medico, Paciente, Producto, Farmacia, Sucursal, Receta, DetalleReceta, DetallePrescripcion, ProductoFarmacia
)

class UserSerializer(serializers.ModelSerializer):
	class Meta:
		model = User
		fields = [
			'id', 'username', 'first_name', 'last_name', 'email',
			'is_active', 'is_staff', 'is_superuser', 'date_joined', 'last_login'
		]

class PacienteSerializer(serializers.ModelSerializer):
	user = UserSerializer(read_only=True)
	class Meta:
		model = Paciente
		fields = '__all__'

class MedicoSerializer(serializers.ModelSerializer):
	user = UserSerializer(read_only=True)
	class Meta:
		model = Medico
		fields = '__all__'

class ProductoSerializer(serializers.ModelSerializer):
	class Meta:
		model = Producto
		fields = '__all__'

class FarmaciaSerializer(serializers.ModelSerializer):
	class Meta:
		model = Farmacia
		fields = '__all__'

class ProductoFarmaciaSerializer(serializers.ModelSerializer):
	producto = ProductoSerializer(read_only=True)
	farmacia = FarmaciaSerializer(read_only=True)
	class Meta:
		model = ProductoFarmacia
		fields = '__all__'

class SucursalSerializer(serializers.ModelSerializer):
	farmacia = FarmaciaSerializer(read_only=True)
	class Meta:
		model = Sucursal
		fields = '__all__'

class DetalleRecetaSerializer(serializers.ModelSerializer):
	producto = ProductoSerializer(read_only=True)
	class Meta:
		model = DetalleReceta
		fields = '__all__'

class RecetaSerializer(serializers.ModelSerializer):
	medico = MedicoSerializer(read_only=True)
	paciente = PacienteSerializer(read_only=True)
	detalles = DetalleRecetaSerializer(many=True, read_only=True)
	class Meta:
		model = Receta
		fields = '__all__'

class DetallePrescripcionSerializer(serializers.ModelSerializer):
	detalle_receta = DetalleRecetaSerializer(read_only=True)
	farmacia = FarmaciaSerializer(read_only=True)
	producto = ProductoSerializer(read_only=True)
	producto_farmacia = ProductoFarmaciaSerializer(read_only=True)
	
	class Meta:
		model = DetallePrescripcion
		fields = '__all__'
	
	def to_representation(self, instance):
		"""
		Sobrescribe el método para usar el precio de ProductoFarmacia si existe,
		en lugar del precio_encontrado guardado.
		"""
		representation = super().to_representation(instance)
		
		# Si existe producto_farmacia, usar su precio actualizado
		if instance.producto_farmacia:
			representation['precio_encontrado'] = str(instance.producto_farmacia.precio)
			representation['precio_origen'] = 'ProductoFarmacia (precio oficial)'
		# Si no existe pero podemos buscarlo dinámicamente
		elif instance.producto and instance.farmacia:
			try:
				from login.models import ProductoFarmacia
				producto_farmacia = ProductoFarmacia.objects.get(
					producto=instance.producto,
					farmacia=instance.farmacia
				)
				representation['precio_encontrado'] = str(producto_farmacia.precio)
				representation['precio_origen'] = 'ProductoFarmacia (precio oficial actualizado)'
			except ProductoFarmacia.DoesNotExist:
				# Mantener el precio_encontrado original
				representation['precio_origen'] = f'Manual/Scraping - {instance.fuente}'
		else:
			representation['precio_origen'] = f'Manual/Scraping - {instance.fuente}'
		
		return representation

