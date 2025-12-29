from django.contrib import admin
from authentication.models import Medico, Paciente, RefreshToken, RevokedToken


@admin.register(Medico)
class MedicoAdmin(admin.ModelAdmin):
    list_display = ('user', 'numero_licencia', 'institucion', 'ubicacion_consultorio')
    search_fields = ('user__username', 'user__email', 'numero_licencia', 'institucion')
    ordering = ('user__username',)


@admin.register(Paciente)
class PacienteAdmin(admin.ModelAdmin):
    list_display = ('user', 'cedula', 'fecha_nacimiento', 'telefono')
    search_fields = ('user__username', 'user__email', 'cedula')
    ordering = ('user__username',)


@admin.register(RefreshToken)
class RefreshTokenAdmin(admin.ModelAdmin):
    list_display = ('user', 'jti', 'created_at', 'expires_at', 'ip_address')
    list_filter = ('created_at', 'expires_at')
    search_fields = ('user__email', 'jti', 'ip_address')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)


@admin.register(RevokedToken)
class RevokedTokenAdmin(admin.ModelAdmin):
    list_display = ('jti', 'token_type', 'user', 'reason', 'revoked_at', 'expires_at')
    list_filter = ('token_type', 'reason', 'revoked_at')
    search_fields = ('jti', 'user__email')
    readonly_fields = ('id', 'revoked_at')
    ordering = ('-revoked_at',)
