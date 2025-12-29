from rest_framework import serializers
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import Medico, Paciente


class MedicoSerializer(serializers.ModelSerializer):
    """Serializer para el modelo Medico"""
    class Meta:
        model = Medico
        fields = ('tipo_usuario', 'numero_licencia', 'institucion', 'ubicacion_consultorio')


class PacienteSerializer(serializers.ModelSerializer):
    """Serializer para el modelo Paciente"""
    class Meta:
        model = Paciente
        fields = ('tipo_usuario', 'fecha_nacimiento', 'cedula', 'direccion', 'telefono')


class UserRegisterSerializer(serializers.Serializer):
    """Serializer para registro de usuarios (médicos y pacientes)"""
    # Campos del User de Django
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True)
    first_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    
    # Campo para identificar tipo
    tipo_usuario = serializers.ChoiceField(choices=['medico', 'paciente'])
    
    # Campos de Medico
    numero_licencia = serializers.CharField(max_length=50, required=False, allow_blank=True)
    institucion = serializers.CharField(max_length=150, required=False, allow_blank=True)
    ubicacion_consultorio = serializers.CharField(max_length=255, required=False, allow_blank=True)
    
    # Campos de Paciente
    fecha_nacimiento = serializers.DateField(required=False, allow_null=True)
    cedula = serializers.CharField(max_length=20, required=False, allow_blank=True)
    direccion = serializers.CharField(max_length=255, required=False, allow_blank=True)
    telefono = serializers.CharField(max_length=20, required=False, allow_blank=True)
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Las contraseñas no coinciden."})
        
        tipo = attrs.get('tipo_usuario')
        
        # Validaciones para médico
        if tipo == 'medico':
            if not attrs.get('numero_licencia'):
                raise serializers.ValidationError({
                    "numero_licencia": "El número de licencia es obligatorio para médicos."
                })
            if not attrs.get('institucion'):
                raise serializers.ValidationError({
                    "institucion": "La institución es obligatoria para médicos."
                })
            if not attrs.get('ubicacion_consultorio'):
                raise serializers.ValidationError({
                    "ubicacion_consultorio": "La ubicación del consultorio es obligatoria para médicos."
                })
        
        # Validaciones para paciente
        if tipo == 'paciente':
            if not attrs.get('fecha_nacimiento'):
                raise serializers.ValidationError({
                    "fecha_nacimiento": "La fecha de nacimiento es obligatoria para pacientes."
                })
            if not attrs.get('cedula'):
                raise serializers.ValidationError({
                    "cedula": "La cédula es obligatoria para pacientes."
                })
            if not attrs.get('direccion'):
                raise serializers.ValidationError({
                    "direccion": "La dirección es obligatoria para pacientes."
                })
            if not attrs.get('telefono'):
                raise serializers.ValidationError({
                    "telefono": "El teléfono es obligatorio para pacientes."
                })
        
        return attrs
    
    def create(self, validated_data):
        tipo_usuario = validated_data.pop('tipo_usuario')
        validated_data.pop('password2')
        
        # Crear usuario de Django
        user = User.objects.create_user(
            username=validated_data.get('username'),
            email=validated_data.get('email'),
            password=validated_data.get('password'),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        
        # Crear perfil según tipo de usuario
        if tipo_usuario == 'medico':
            Medico.objects.create(
                user=user,
                tipo_usuario='medico',
                numero_licencia=validated_data.get('numero_licencia'),
                institucion=validated_data.get('institucion'),
                ubicacion_consultorio=validated_data.get('ubicacion_consultorio')
            )
        elif tipo_usuario == 'paciente':
            Paciente.objects.create(
                user=user,
                tipo_usuario='paciente',
                fecha_nacimiento=validated_data.get('fecha_nacimiento'),
                cedula=validated_data.get('cedula'),
                direccion=validated_data.get('direccion'),
                telefono=validated_data.get('telefono')
            )
        
        return user


class UserLoginSerializer(serializers.Serializer):
    """Serializer para login"""
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, write_only=True)
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        
        if email and password:
            user = authenticate(request=self.context.get('request'),
                              username=email, password=password)
            
            if not user:
                raise serializers.ValidationError('Credenciales inválidas.')
            
            if not user.is_active:
                raise serializers.ValidationError('Usuario inactivo.')
            
            attrs['user'] = user
            return attrs
        else:
            raise serializers.ValidationError('Email y contraseña son requeridos.')


class UserSerializer(serializers.ModelSerializer):
    """Serializer para información del usuario"""
    medico = MedicoSerializer(source='medico', read_only=True)
    paciente = PacienteSerializer(source='paciente', read_only=True)
    
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name',
                 'is_active', 'date_joined', 'last_login', 'medico', 'paciente')
        read_only_fields = ('id', 'date_joined', 'last_login')


class TokenRefreshSerializer(serializers.Serializer):
    """Serializer para refresh token"""
    refresh = serializers.CharField(required=True)


class TokenValidateSerializer(serializers.Serializer):
    """Serializer para validar tokens"""
    token = serializers.CharField(required=True)
