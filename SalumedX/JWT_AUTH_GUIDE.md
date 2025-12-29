"""
📚 GUÍA DE USO - Autenticación JWT con Auth Service
===================================================

## 🔑 Configuración Previa

1. **Mismo SECRET_KEY en ambos servicios:**
   - Copia el SECRET_KEY del auth-service/.env
   - Pégalo en SalumedX/.env
   
   Ejemplo:
   ```bash
   # En auth-service/.env
   SECRET_KEY=your-secret-key-change-in-production-xyz123
   
   # En SalumedX/.env (debe ser IDÉNTICO)
   SECRET_KEY=your-secret-key-change-in-production-xyz123
   ```

2. **URL del Auth Service:**
   ```bash
   # En SalumedX/.env
   AUTH_SERVICE_URL=http://localhost:8001
   ```

## 📡 Flujo de Autenticación

```
┌──────────┐    1. Login/Register    ┌──────────────┐
│ Frontend │ ─────────────────────►  │ Auth Service │
│          │                          │  (port 8001) │
│          │ ◄─────────────────────  │              │
└──────────┘   2. Devuelve JWT       └──────────────┘
     │              tokens
     │
     │ 3. Usa token JWT
     │    en header
     ▼
┌──────────────┐
│  SalumedX    │  4. Valida JWT localmente
│  REST API    │     (sin llamar a auth-service)
│ (port 8000)  │  5. Extrae user_id del token
└──────────────┘  6. Busca usuario en DB local

```

## 🎯 Uso en Vistas (3 opciones)

### Opción 1: Decorador @jwt_required (Nuevo - Simple)
Para vistas que REQUIEREN autenticación:

```python
from django.http import JsonResponse
from login.decorators import jwt_required

@jwt_required
def mi_vista_protegida(request):
    # El usuario está garantizado en request.jwt_user
    user = request.jwt_user
    
    return JsonResponse({
        'message': f'Hola {user.username}',
        'user_id': str(user.id),
        'email': user.email,
        'tipo': user.tipo_usuario
    })
```

### Opción 2: Decorador @jwt_optional
Para vistas que funcionan con o sin autenticación:

```python
from django.http import JsonResponse
from login.decorators import jwt_optional

@jwt_optional
def mi_vista_publica(request):
    # request.jwt_user puede ser None
    if request.jwt_user:
        mensaje = f'Hola {request.jwt_user.username}'
    else:
        mensaje = 'Hola invitado'
    
    return JsonResponse({'message': mensaje})
```

### Opción 3: DRF @permission_classes (Ya existente)
Sigue funcionando como antes:

```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def mi_vista_drf(request):
    # request.user es el usuario de Django (session/JWT)
    # request.jwt_user es el usuario validado por JWT
    
    user = request.user  # O request.jwt_user
    return Response({'user': user.username})
```

## 🧪 Ejemplo Completo: Crear Receta con JWT

```python
from django.http import JsonResponse
from login.decorators import jwt_required
from login.models import Receta, Medico, Paciente
import json

@jwt_required
def crear_receta(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Método no permitido'}, status=405)
    
    user = request.jwt_user
    
    # Verificar que es médico
    if user.tipo_usuario != 'medico':
        return JsonResponse({
            'error': 'Solo médicos pueden crear recetas'
        }, status=403)
    
    try:
        data = json.loads(request.body)
        
        # Obtener perfil de médico
        medico_profile = user.medico_profile
        
        # Crear receta
        receta = Receta.objects.create(
            medico=medico_profile,
            paciente_id=data['paciente_id'],
            diagnostico=data['diagnostico'],
            observaciones=data.get('observaciones', '')
        )
        
        return JsonResponse({
            'success': True,
            'receta_id': receta.id,
            'medico': user.get_full_name()
        }, status=201)
        
    except Exception as e:
        return JsonResponse({
            'error': str(e)
        }, status=400)
```

## 🔍 Verificar JWT Manualmente

```python
import jwt
from django.conf import settings

def verificar_token_manual(token):
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=['HS256']
        )
        print(f"Token válido. User ID: {payload['user_id']}")
        print(f"Expira: {payload['exp']}")
        return payload
    except jwt.ExpiredSignatureError:
        print("Token expirado")
    except jwt.InvalidTokenError:
        print("Token inválido")
```

## 🧪 Probar con cURL

```bash
# 1. Login en auth-service
curl -X POST http://localhost:8001/auth/login \\
  -H "Content-Type: application/json" \\
  -d '{
    "email": "medico@test.com",
    "password": "password123"
  }'

# Respuesta:
# {
#   "tokens": {
#     "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#     "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
#   }
# }

# 2. Usar token en SalumedX
curl http://localhost:8000/api/recetas/ \\
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

## 🚨 Importante

1. **El SECRET_KEY DEBE ser idéntico** en ambos servicios
2. **No se hacen llamadas al auth-service** para cada request (solo local)
3. **El usuario debe existir en ambas bases de datos** con el mismo UUID
4. **Para sincronizar usuarios**, considera:
   - Opción A: Webhook cuando se crea usuario en auth-service
   - Opción B: Script de sincronización periódica
   - Opción C: API call de auth-service a SalumedX al registrar

## 🔄 Sincronización de Usuarios (Opcional)

Si los usuarios solo existen en auth-service, puedes:

```python
# En SalumedX, cuando recibas un JWT válido:
from login.models import User

def sync_user_from_jwt(jwt_payload):
    user_id = jwt_payload['user_id']
    email = jwt_payload.get('email')
    
    # Crear usuario si no existe
    user, created = User.objects.get_or_create(
        id=user_id,
        defaults={'email': email, 'username': email.split('@')[0]}
    )
    
    return user
```

## 📝 Notas Finales

- El middleware `JWTAuthenticationMiddleware` se ejecuta automáticamente
- No necesitas modificar código existente si usas DRF
- Los decoradores `@jwt_required` y `@jwt_optional` son para vistas simples (no DRF)
- La validación es **local y rápida** (sin latencia de red)
"""
