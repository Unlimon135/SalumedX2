from django.db import models
from django.conf import settings
from django.contrib.auth.models import User  #Esta es la entidad base de usuario de Django

# Create your models here.
    
#IMPORTENTEEEEEEEEEEEEE
#Usuario se eliminó porque Django ya proporciona un modelo User que tiene validaciones integradas y funcionalidades de autenticación.

#------Clase User ------

#((((ATRIBUTOS))))
#username → Nombre de usuario único (obligatorio).

#first_name → Nombre(s) del usuario.

#last_name → Apellido(s) del usuario.

#email → Correo electrónico.

#password → Contraseña (almacenada en hash).

#is_staff → Booleano, indica si el usuario puede acceder al admin de Django.

#is_active → Booleano, indica si la cuenta está activa.

#is_superuser → Booleano, indica si es administrador con todos los permisos.

#last_login → Fecha/hora del último login.

#date_joined → Fecha/hora en que se creó el usuario.

#((((METODOS))))----------------------------------------------------------------------------
#get_full_name() → Devuelve first_name + last_name.

#get_short_name() → Devuelve first_name.

#check_password() → Verifica si un password coincide.

#set_password() → Para cambiar la contraseña correctamente.


class Paciente(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)  #Esto importa el modelo User de Django
    # Campos específicos del paciente
    fecha_nacimiento = models.DateField()
    tipo_usuario = models.CharField(max_length=20, default='paciente')
    cedula = models.CharField(max_length=20, unique=True)
    direccion = models.CharField(max_length=255)
    telefono = models.CharField(max_length=20)

    def __str__(self):
        return f"{self.user.get_full_name()}"

class Medico(models.Model):#--------El tipo de usaurio se validará en los servicios de autenticación------
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    # Campos específicos del médico
    tipo_usuario = models.CharField(max_length=20, default='medico')
    numero_licencia = models.CharField(max_length=50)
    institucion = models.CharField(max_length=150)
    ubicacion_consultorio = models.CharField(max_length=255)

    def __str__(self):
        return f"Dr. {self.user.get_full_name()}"

class Producto(models.Model):
    id_producto = models.AutoField(primary_key=True)
    nombre_generico = models.CharField(max_length=150)
    nombre_comercial = models.CharField(max_length=150)
    principio_activo = models.CharField(max_length=150)
    categoria = models.CharField(max_length=100)
    presentacion = models.CharField(max_length=100)
    concentracion = models.CharField(max_length=100)
    requiere_receta = models.BooleanField(default=False)
    precio_base = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, help_text="Precio de referencia del producto")

    def __str__(self):
        return self.nombre_comercial


class Farmacia(models.Model):
    id_farmacia = models.AutoField(primary_key=True)
    nombre_comercial = models.CharField(max_length=150)
    horario_atencion = models.CharField(max_length=100)

    def __str__(self):
        return self.nombre_comercial


class Sucursal(models.Model):
    id_sucursal = models.AutoField(primary_key=True)
    farmacia = models.ForeignKey(Farmacia, on_delete=models.CASCADE)
    ubicacion = models.CharField(max_length=100, default='No especificada')
    longitud = models.DecimalField(max_digits=9, decimal_places=6)
    latitud = models.DecimalField(max_digits=9, decimal_places=6)

    def __str__(self):
        return f"Sucursal de {self.farmacia.nombre_comercial}"


class ProductoFarmacia(models.Model):
    """
    Tabla intermedia que define el precio de un producto en una farmacia específica.
    Solo el admin puede gestionar estos precios.
    """
    id_producto_farmacia = models.AutoField(primary_key=True)
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='precios_por_farmacia')
    farmacia = models.ForeignKey(Farmacia, on_delete=models.CASCADE, related_name='productos_disponibles')
    precio = models.DecimalField(max_digits=10, decimal_places=2, help_text="Precio del producto en esta farmacia")
    fecha_actualizacion = models.DateTimeField(auto_now=True, help_text="Última actualización del precio")

    class Meta:
        unique_together = ('producto', 'farmacia')  # Un producto solo puede tener un precio por farmacia
        verbose_name = 'Precio de Producto por Farmacia'
        verbose_name_plural = 'Precios de Productos por Farmacia'

    def __str__(self):
        return f"{self.producto.nombre_comercial} en {self.farmacia.nombre_comercial} - ${self.precio}"


class Receta(models.Model):
    id_receta = models.AutoField(primary_key=True)
    medico = models.ForeignKey(Medico, on_delete=models.CASCADE)
    paciente = models.ForeignKey(Paciente, on_delete=models.CASCADE)
    fecha_emision = models.DateField()
    diagnostico = models.TextField()
    observaciones = models.TextField(blank=True, null=True)
    ubicacion_emision = models.CharField(max_length=255)

    def __str__(self):
        # paciente no tiene campo 'nombre' cuando usamos User; usamos get_full_name()
        paciente_name = getattr(self.paciente.user, 'get_full_name', None)
        if callable(paciente_name):
            display = self.paciente.user.get_full_name()
        else:
            display = str(self.paciente.user)
        return f"Receta #{self.id_receta} - {display}"


class DetalleReceta(models.Model):
    id_detalle_receta = models.AutoField(primary_key=True)
    receta = models.ForeignKey(Receta, on_delete=models.CASCADE, related_name="detalles")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    cantidad = models.PositiveIntegerField()
    dosis = models.CharField(max_length=100)
    presentacion = models.CharField(max_length=100)
    duracion_tratamiento = models.CharField(max_length=100)
    instrucciones = models.TextField()

    def __str__(self):
        paciente_name = getattr(self.receta.paciente.user, 'get_full_name', None)
        if callable(paciente_name):
            display = self.receta.paciente.user.get_full_name()
        else:
            display = str(self.receta.paciente.user)
        return f"{self.producto.nombre_comercial} - {display}"


class DetallePrescripcion(models.Model):
    """
    Representa el resultado de una búsqueda de precios para un medicamento recetado.
    El precio_encontrado se obtiene de ProductoFarmacia o se registra manualmente si proviene de fuentes externas.
    """
    id_detalle_prescripcion = models.AutoField(primary_key=True)
    detalle_receta = models.ForeignKey(DetalleReceta, on_delete=models.CASCADE, related_name='resultados_busqueda')
    producto_farmacia = models.ForeignKey(
        'ProductoFarmacia', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        help_text="Referencia al precio oficial en ProductoFarmacia (si existe)"
    )
    farmacia = models.ForeignKey(Farmacia, on_delete=models.CASCADE)
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    precio_encontrado = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        help_text="Precio encontrado (puede venir de ProductoFarmacia o de fuentes externas)"
    )
    distancia = models.DecimalField(max_digits=6, decimal_places=2, help_text="Distancia en km desde el paciente")
    fecha_consulta = models.DateTimeField(auto_now_add=True)
    fuente = models.CharField(max_length=150, help_text="De dónde proviene el precio (ej: 'Base de datos', 'Web scraping', etc.)")

    class Meta:
        verbose_name = 'Detalle de Prescripción'
        verbose_name_plural = 'Detalles de Prescripciones'

    def __str__(self):
        return f"{self.producto.nombre_comercial} en {self.farmacia.nombre_comercial} - ${self.precio_encontrado}"


class ConsultaProducto(models.Model):
    """
    Registra búsquedas/consultas de precios de usuarios (con o sin receta).
    Útil para:
    - Historial de búsquedas de usuarios registrados
    - Analítica de productos más consultados
    - Favoritos o productos de interés
    - Registros de usuarios anónimos (user=None)
    """
    id_consulta = models.AutoField(primary_key=True)
    user = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='consultas_productos',
        help_text="Usuario que realizó la consulta (null si es anónimo)"
    )
    producto = models.ForeignKey(
        Producto, 
        on_delete=models.CASCADE,
        related_name='consultas'
    )
    farmacia = models.ForeignKey(
        Farmacia, 
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        help_text="Farmacia consultada (opcional si es búsqueda general)"
    )
    producto_farmacia = models.ForeignKey(
        ProductoFarmacia,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Referencia al precio oficial consultado"
    )
    precio_visto = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Precio que vio el usuario en el momento de la consulta"
    )
    origen = models.CharField(
        max_length=50,
        default='public_search',
        help_text="Origen de la consulta: 'public_search', 'user_interest', 'saved', 'comparison'"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Consulta de Producto'
        verbose_name_plural = 'Consultas de Productos'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['producto', '-created_at']),
        ]

    def __str__(self):
        user_display = self.user.username if self.user else 'Anónimo'
        farmacia_display = self.farmacia.nombre_comercial if self.farmacia else 'General'
        return f"{user_display} - {self.producto.nombre_comercial} en {farmacia_display}"


