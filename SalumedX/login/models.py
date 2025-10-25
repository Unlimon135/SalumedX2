from django.db import models

# Create your models here.
class Usuario(models.Model):
    id_usuario = models.AutoField(primary_key=True)
    nombre = models.CharField(max_length=100)
    apellido = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    contraseña = models.CharField(max_length=128)
    tipo_usuario = models.CharField(max_length=50)
    fecha_registro = models.DateTimeField(auto_now_add=True)
    estado = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.nombre} {self.apellido}"


class Medico(models.Model):
    id_medico = models.AutoField(primary_key=True)
    usuario = models.OneToOneField(Usuario, on_delete=models.CASCADE)
    numero_licencia = models.CharField(max_length=50)
    institucion = models.CharField(max_length=150)
    ubicacion_consultorio = models.CharField(max_length=255)

    def __str__(self):
        return f"Dr. {self.usuario.nombre} {self.usuario.apellido}"


class Paciente(models.Model):
    id_paciente = models.AutoField(primary_key=True)
    usuario = models.OneToOneField(Usuario, on_delete=models.CASCADE)
    nombre = models.CharField(max_length=100)
    fecha_nacimiento = models.DateField()
    cedula = models.CharField(max_length=20, unique=True)
    direccion = models.CharField(max_length=255)
    telefono = models.CharField(max_length=20)

    def __str__(self):
        return self.nombre


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
        return f"Receta #{self.id_receta} - {self.paciente.nombre}"


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
        return f"{self.producto.nombre_comercial} - {self.receta.paciente.nombre}"


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
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    termino_busqueda = models.CharField(max_length=255)
    fecha_hora = models.DateTimeField(auto_now_add=True)
    resultados_mostrados = models.IntegerField()
    farmacia_seleccionada = models.ForeignKey(Farmacia, on_delete=models.SET_NULL, null=True, blank=True)
    geolocalizacion = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"Búsqueda de {self.usuario.nombre} - {self.termino_busqueda}"