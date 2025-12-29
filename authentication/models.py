from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone
import uuid


class Paciente(models.Model):
    """Modelo de Paciente - Compatible con REST API"""
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    # Campos específicos del paciente
    fecha_nacimiento = models.DateField()
    tipo_usuario = models.CharField(max_length=20, default='paciente')
    cedula = models.CharField(max_length=20, unique=True)
    direccion = models.CharField(max_length=255)
    telefono = models.CharField(max_length=20)

    def __str__(self):
        return f"{self.user.get_full_name()}"


class Medico(models.Model):
    """Modelo de Médico - Compatible con REST API"""
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    # Campos específicos del médico
    tipo_usuario = models.CharField(max_length=20, default='medico')
    numero_licencia = models.CharField(max_length=50)
    institucion = models.CharField(max_length=150)
    ubicacion_consultorio = models.CharField(max_length=255)

    def __str__(self):
        return f"Dr. {self.user.get_full_name()}"


class RefreshToken(models.Model):
    """Modelo para almacenar refresh tokens"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='refresh_tokens')
    token = models.CharField(max_length=500, unique=True)
    jti = models.CharField(max_length=255, unique=True)  # JWT ID
    
    created_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField()
    
    # Metadata para seguridad
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=500, blank=True)
    
    class Meta:
        db_table = 'refresh_tokens'
        verbose_name = 'Refresh Token'
        verbose_name_plural = 'Refresh Tokens'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['jti']),
        ]
    
    def __str__(self):
        return f"RefreshToken for {self.user.email}"
    
    def is_expired(self):
        return timezone.now() >= self.expires_at


class RevokedToken(models.Model):
    """Modelo para tokens revocados (blacklist)"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    jti = models.CharField(max_length=255, unique=True, db_index=True)
    token_type = models.CharField(max_length=10, choices=[
        ('access', 'Access Token'),
        ('refresh', 'Refresh Token'),
    ])
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='revoked_tokens', null=True)
    revoked_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField()
    
    reason = models.CharField(max_length=255, blank=True, choices=[
        ('logout', 'Usuario cerró sesión'),
        ('password_change', 'Cambio de contraseña'),
        ('security', 'Razones de seguridad'),
        ('expired', 'Token expirado'),
    ])
    
    class Meta:
        db_table = 'revoked_tokens'
        verbose_name = 'Token Revocado'
        verbose_name_plural = 'Tokens Revocados'
        ordering = ['-revoked_at']
        indexes = [
            models.Index(fields=['jti']),
            models.Index(fields=['-revoked_at']),
        ]
    
    def __str__(self):
        return f"Revoked {self.token_type} token - {self.jti[:8]}..."
