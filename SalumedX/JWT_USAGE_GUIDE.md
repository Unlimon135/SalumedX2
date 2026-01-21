# 🔐 Guía de Uso - Sistema JWT con Auth-Service

## 📋 Resumen

Tu API REST ahora valida **tokens JWT** emitidos por el **auth-service (puerto 8001)** de forma local, sin necesidad de llamadas constantes al servicio externo. El sistema maneja automáticamente:

- ✅ Validación de firma del token
- ✅ Verificación de expiración (5 horas)
- ✅ Respuestas claras cuando el token expira
- ✅ Información del usuario desde el token
- ✅ Headers informativos sobre el estado del token

---

## 🔄 Flujo de Autenticación

### 1️⃣ Login (Obtener Token)

**Endpoint:** `POST /auth/login/`

```bash
curl -X POST http://localhost:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "medico@test.com",
    "password": "12345678"
  }'
```

**Respuesta:**
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "medico@test.com",
    "username": "medico",
    "tipo_usuario": "medico"
  },
  "token_info": {
    "usage": "Incluir en header: Authorization: Bearer <access_token>",
    "expires_in": "5 horas",
    "refresh_usage": "Usar refresh token en /token/refresh/ para obtener nuevo access token"
  }
}
```

### 2️⃣ Usar el Token en Requests

**Todos los endpoints protegidos** requieren el token en el header:

```bash
# Ejemplo: Crear receta
curl -X POST http://localhost:8000/recetas/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "paciente": 1,
    "diagnostico": "Gripe común",
    "detalles": [...]
  }'
```

### 3️⃣ Verificar Estado del Token

**Endpoint:** `GET /token/status/`

```bash
curl -X GET http://localhost:8000/token/status/ \
  -H "Authorization: Bearer <tu_token>"
```

**Respuesta (Token válido):**
```json
{
  "authenticated": true,
  "user_id": 1,
  "user_info": {
    "username": "medico",
    "email": "medico@test.com",
    "tipo_usuario": "medico",
    "is_staff": false
  },
  "expiration_time": "2026-01-18T18:30:00",
  "remaining_time": "4h 25m",
  "remaining_seconds": 15900,
  "message": "Token válido"
}
```

**Respuesta (Token expirado):**
```json
{
  "authenticated": false,
  "expired": true,
  "message": "El token ha expirado",
  "user_id": 1,
  "expiration_time": "2026-01-18T13:30:00"
}
```

### 4️⃣ Refrescar Token (Cuando Expire)

**Endpoint:** `POST /token/refresh/`

```bash
curl -X POST http://localhost:8000/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "<tu_refresh_token>"
  }'
```

**Respuesta:**
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 🔒 Endpoints Protegidos

### Con JWT Requerido (`@permission_classes([IsAuthenticated])` o `@jwt_required`)

Estos endpoints **REQUIEREN** token válido:

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET/POST | `/recetas/` | Listar/crear recetas |
| POST | `/detalle-prescripcion/` | Detalles de prescripción |
| GET | `/paciente-info/` | Info del paciente actual |
| GET | `/medico-info/` | Info del médico actual |
| POST | `/api/admin/productos/` | Admin: Gestión de productos |
| POST | `/api/admin/farmacias/` | Admin: Gestión de farmacias |

### Públicos (No requieren token)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/auth/login/` | Login |
| POST | `/auth/register/` | Registro |
| GET | `/token/status/` | Verificar token |
| GET | `/productos/` | Listar productos |
| GET | `/farmacias/` | Listar farmacias |

---

## ⚠️ Manejo de Errores

### Token Expirado (401)

```json
{
  "error": "Token expirado",
  "detail": "Tu sesión ha expirado. Por favor, inicia sesión nuevamente.",
  "code": "TOKEN_EXPIRED"
}
```

**Solución:** Usar el refresh token en `/token/refresh/` o hacer login nuevamente.

### Token Inválido (401)

```json
{
  "error": "Token inválido",
  "detail": "Token inválido: Signature verification failed",
  "code": "TOKEN_INVALID"
}
```

**Solución:** El token está corrupto o fue manipulado. Hacer login nuevamente.

### Sin Token (401)

```json
{
  "error": "Autenticación requerida",
  "detail": "Token JWT válido requerido en el header Authorization",
  "code": "AUTH_REQUIRED"
}
```

**Solución:** Agregar el header `Authorization: Bearer <token>`.

---

## 🔧 Headers Informativos

El middleware agrega headers automáticos en **todas las respuestas**:

```http
X-Token-Status: valid          # Estado del token (valid/expired/invalid)
X-Token-Error: Token expirado  # Mensaje de error (solo si hay error)
```

---

## 📱 Ejemplo Completo (Frontend)

### JavaScript/Axios

```javascript
// 1. Login
const login = async (email, password) => {
  const response = await axios.post('http://localhost:8000/auth/login/', {
    email,
    password
  });
  
  // Guardar tokens
  localStorage.setItem('access_token', response.data.access);
  localStorage.setItem('refresh_token', response.data.refresh);
  
  return response.data;
};

// 2. Configurar interceptor para agregar token
axios.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 3. Manejar expiración
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    // Si el token expiró
    if (error.response?.status === 401 && 
        error.response?.data?.code === 'TOKEN_EXPIRED' &&
        !originalRequest._retry) {
      
      originalRequest._retry = true;
      
      try {
        // Refrescar token
        const refresh = localStorage.getItem('refresh_token');
        const response = await axios.post('http://localhost:8000/token/refresh/', {
          refresh
        });
        
        // Guardar nuevo token
        localStorage.setItem('access_token', response.data.access);
        
        // Reintentar request original
        originalRequest.headers.Authorization = `Bearer ${response.data.access}`;
        return axios(originalRequest);
        
      } catch (refreshError) {
        // Refresh falló, redirigir a login
        localStorage.clear();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

// 4. Usar en requests
const crearReceta = async (data) => {
  // El token se agrega automáticamente por el interceptor
  const response = await axios.post('http://localhost:8000/recetas/', data);
  return response.data;
};

// 5. Verificar estado del token periódicamente
const checkTokenStatus = async () => {
  try {
    const response = await axios.get('http://localhost:8000/token/status/');
    console.log(`Token válido. Expira en: ${response.data.remaining_time}`);
    
    // Advertir al usuario si queda poco tiempo
    if (response.data.remaining_seconds < 300) { // menos de 5 minutos
      alert('Tu sesión está por expirar');
    }
  } catch (error) {
    if (error.response?.data?.expired) {
      // Token expirado, refrescar o redirigir a login
      console.log('Token expirado');
    }
  }
};

// Verificar cada 5 minutos
setInterval(checkTokenStatus, 5 * 60 * 1000);
```

---

## 🛠️ Decoradores Disponibles

### Para Vistas Funcionales de Django

```python
from login.decorators import jwt_required, jwt_optional, jwt_required_staff

# Requiere autenticación JWT
@jwt_required
def mi_vista_protegida(request):
    user = request.jwt_user  # Usuario autenticado
    user_id = request.jwt_payload['user_id']
    return JsonResponse({'user_id': user_id})

# Opcional (funciona con o sin JWT)
@jwt_optional
def mi_vista_publica(request):
    if request.jwt_user:
        # Usuario autenticado
        return JsonResponse({'message': f'Hola {request.jwt_user.username}'})
    else:
        # Usuario anónimo
        return JsonResponse({'message': 'Hola visitante'})

# Requiere JWT + usuario staff/admin
@jwt_required_staff
def mi_vista_admin(request):
    # Solo accesible para administradores
    return JsonResponse({'message': 'Panel de admin'})
```

### Para Vistas DRF (Django REST Framework)

```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])  # Valida automáticamente el JWT
def recetas(request):
    # request.user está disponible automáticamente
    user = request.user
    
    if hasattr(user, 'medico'):
        # Usuario es médico
        pass
    
    return Response({'data': 'ok'})
```

---

## ⏱️ Configuración de Tiempos

**En `settings.py`:**

```python
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=5),   # Token expira en 5 horas
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),   # Refresh expira en 7 días
    'ROTATE_REFRESH_TOKENS': True,                 # Generar nuevo refresh al usar el actual
    'BLACKLIST_AFTER_ROTATION': True,              # Invalidar el refresh anterior
}
```

---

## 🎯 Mejores Prácticas

1. **Guardar tokens de forma segura**
   - En frontend: `localStorage` o `sessionStorage`
   - NO enviar el token en URLs o query params

2. **Verificar estado del token periódicamente**
   - Usar `/token/status/` cada 5-10 minutos
   - Advertir al usuario cuando quede poco tiempo

3. **Implementar refresh automático**
   - Usar interceptors (Axios) o middleware (fetch)
   - Refrescar el token cuando expire automáticamente

4. **Manejar errores correctamente**
   - Verificar el código de error (`TOKEN_EXPIRED`, `TOKEN_INVALID`)
   - Redirigir a login cuando el refresh falle

5. **HTTPS en producción**
   - SIEMPRE usar HTTPS en producción
   - Los tokens son sensibles y no deben viajar sin cifrar

---

## 🧪 Testing

### Con cURL

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"medico@test.com","password":"12345678"}' \
  | jq -r '.access')

# 2. Usar token
curl -X GET http://localhost:8000/recetas/ \
  -H "Authorization: Bearer $TOKEN"

# 3. Verificar estado
curl -X GET http://localhost:8000/token/status/ \
  -H "Authorization: Bearer $TOKEN"
```

### Con Postman

1. **Login:** POST `/auth/login/` → Copiar `access` token
2. **Configurar Auth:** 
   - Type: Bearer Token
   - Token: `<pegar_token>`
3. **Usar en cualquier request** → El token se enviará automáticamente

---

## 📊 Diagrama de Flujo

```
┌─────────────┐
│  Frontend   │
└──────┬──────┘
       │ 1. POST /auth/login/
       ▼
┌─────────────┐      ┌──────────────┐
│  SalumedX   │─────►│ Auth-Service │
│  REST API   │◄─────│  (Port 8001) │
│ (Port 8000) │      └──────────────┘
└──────┬──────┘
       │ 2. Devuelve JWT
       ▼
┌─────────────┐
│  Frontend   │
│ (Guarda JWT)│
└──────┬──────┘
       │ 3. Usa JWT en requests
       │    Authorization: Bearer <token>
       ▼
┌─────────────┐
│  SalumedX   │
│  REST API   │ 4. Valida JWT LOCALMENTE
│             │    - Verifica firma
│  Middleware │    - Verifica expiración
│             │    - Obtiene user_id
└──────┬──────┘    - Asigna request.user
       │
       │ 5. Si válido: Ejecuta vista
       │    Si expirado: Error 401
       ▼
┌─────────────┐
│  Response   │
└─────────────┘
```

---

## 🚀 ¡Listo!

Tu sistema JWT está completamente funcional y maneja automáticamente:

✅ Validación de tokens del auth-service  
✅ Detección de expiración  
✅ Mensajes de error claros  
✅ Compatibilidad con DRF  
✅ Headers informativos  
✅ Utilidades para verificar estado del token  

¡Ahora puedes usar los tokens JWT en todas tus peticiones protegidas!
