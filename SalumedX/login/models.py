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
    cedula = models.CharField(max_length=20, unique=True)
    direccion = models.CharField(max_length=255)
    telefono = models.CharField(max_length=20)

    def __str__(self):
        return f"{self.user.get_full_name()}"

class Medico(models.Model):#--------El tipo de usaurio se validará en los servicios de autenticación------
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    # Campos específicos del médico
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
    longitud = models.DecimalField(max_digits=9, decimal_places=6)
    latitud = models.DecimalField(max_digits=9, decimal_places=6)

    def __str__(self):
        return f"Sucursal de {self.farmacia.nombre_comercial}"


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
    id_detalle_prescripcion = models.AutoField(primary_key=True)
    detalle_receta = models.ForeignKey(DetalleReceta, on_delete=models.CASCADE)
    farmacia = models.ForeignKey(Farmacia, on_delete=models.CASCADE)
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    precio_encontrado = models.DecimalField(max_digits=10, decimal_places=2)
    distancia = models.DecimalField(max_digits=6, decimal_places=2)
    fecha_consulta = models.DateTimeField(auto_now_add=True)
    fuente = models.CharField(max_length=150)

    def __str__(self):
        return f"{self.producto.nombre_comercial} en {self.farmacia.nombre_comercial}"


class Busqueda(models.Model):
    id_busqueda = models.AutoField(primary_key=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    termino_busqueda = models.CharField(max_length=255)
    fecha_hora = models.DateTimeField(auto_now_add=True)
    resultados_mostrados = models.IntegerField()
    farmacia_seleccionada = models.ForeignKey(Farmacia, on_delete=models.SET_NULL, null=True, blank=True)
    geolocalizacion = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        # Use the default User __str__ (username) for readability
        return f"Búsqueda de {self.user} - {self.termino_busqueda}"