# backend/app/models.py
from django.db import models

#Entidad de farmacia con nombre y localización, por ahora solo tienen estos atributos
class Pharmacy(models.Model):
    name = models.CharField(max_length=100)
    location = models.CharField(max_length=255)

#Entidad de producto con nombre, precio y relación a farmacia
class Product(models.Model):
    pharmacy = models.ForeignKey(Pharmacy, on_delete=models.CASCADE, related_name="products")
    name = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=8, decimal_places=2)

#Aqui se hace la unión de la entidad producto con prescripición, la relación es muchos a muchos
#ya que una prescripción puede tener varios productos y un producto puede estar en varias prescripciones
class Prescription(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    products = models.ManyToManyField(Product, through="PrescriptionItem")

#Entidad intermedia para manejar la relación muchos a muchos entre Prescription y Product
class PrescriptionItem(models.Model):
    prescription = models.ForeignKey(Prescription, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField()
