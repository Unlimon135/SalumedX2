from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone
import uuid


class CustomUserManager(BaseUserManager):
    """Manager personalizado para el modelo de usuario"""
    
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('El email es obligatorio')
        
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """Modelo personalizado de usuario"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, max_length=255)
    username = models.CharField(max_length=150, unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    last_login = models.DateTimeField(null=True, blank=True)
    
    objects = CustomUserManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    
    class Meta:
        db_table = 'users'
        verbose_name = 'Usuario'
        verbose_name_plural = 'Usuarios'
        ordering = ['-created_at']
    
    def __str__(self):
        return self.email
    
    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip() or self.username


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
