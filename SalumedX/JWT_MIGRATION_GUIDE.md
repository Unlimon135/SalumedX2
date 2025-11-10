# 🔐 Guía de Migración a JWT

## Cambios Realizados

Tu API ahora usa **JWT (JSON Web Tokens)** en lugar de cookies de sesión. Esto simplifica la comunicación cross-domain entre:
- Frontend Vue
- Backend Django REST (Render)
- GraphQL Sinatra

---

## 📋 Resumen de Cambios

### ✅ Backend (Django REST)

| Antes | Ahora |
|-------|-------|
| SessionAuthentication | JWTAuthentication |
| Cookies `sessionid`, `csrftoken` | Headers `Authorization: Bearer <token>` |
| `login(request, user)` | `RefreshToken.for_user(user)` |
| No funciona cross-domain | ✅ Funciona cross-domain |

---

## 🚀 Cómo Usar JWT

### 1. **Login** (Devuelve tokens)

**Request:**
```http
POST https://salumedx-rest.onrender.com/signin/
Content-Type: application/json

{
  "username": "usuario",
  "password": "contraseña"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login exitoso",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",  // Token de acceso (5 horas)
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...", // Token de refresco (7 días)
  "user": {
    "id": 1,
    "username": "usuario",
    "email": "usuario@example.com"
  }
}
```

### 2. **Signup** (Crea usuario y devuelve tokens)

**Request:**
```http
POST https://salumedx-rest.onrender.com/signup/
Content-Type: application/json

{
  "username": "nuevo_usuario",
  "password1": "contraseña123",
  "password2": "contraseña123",
  "first_name": "Juan",
  "last_name": "Pérez",
  "email": "juan@example.com",
  "tipo_usuario": "paciente",
  "cedula": "0912345678",
  "direccion": "Guayaquil",
  "telefono": "0999123456"
}
```

**Response (201):**
```json
{
  "success": true,
  "tipo_usuario": "paciente",
  "perfil": {
    "id": 5,
    "user": {...},
    "cedula": "0912345678",
    ...
  },
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### 3. **Peticiones Autenticadas** (Usar access token)

**Request:**
```http
GET https://salumedx-rest.onrender.com/recetas/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Response (200):**
```json
{
  "recetas": [...],
  "total": 5
}
```

### 4. **Refrescar Token** (Cuando access expira)

**Request:**
```http
POST https://salumedx-rest.onrender.com/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response (200):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."  // Nuevo access token
}
```

---

## 💻 Código para Frontend Vue

### Setup (Guardar tokens)

```javascript
// Después de login o signup
const response = await fetch('https://salumedx-rest.onrender.com/signin/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username, password })
});

const data = await response.json();

if (data.success) {
  // Guardar tokens en localStorage
  localStorage.setItem('access_token', data.access);
  localStorage.setItem('refresh_token', data.refresh);
  localStorage.setItem('user', JSON.stringify(data.user));
}
```

### Peticiones Autenticadas

```javascript
async function fetchRecetas() {
  const token = localStorage.getItem('access_token');
  
  const response = await fetch('https://salumedx-rest.onrender.com/recetas/', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (response.status === 401) {
    // Token expiró, refrescar
    await refreshToken();
    // Reintentar petición
    return fetchRecetas();
  }
  
  return response.json();
}
```

### Refrescar Token Automáticamente

```javascript
async function refreshToken() {
  const refresh = localStorage.getItem('refresh_token');
  
  const response = await fetch('https://salumedx-rest.onrender.com/token/refresh/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh })
  });
  
  if (response.ok) {
    const data = await response.json();
    localStorage.setItem('access_token', data.access);
  } else {
    // Refresh token inválido, hacer logout
    logout();
  }
}

function logout() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  localStorage.removeItem('user');
  // Redirigir a login
}
```

### Interceptor Global (Composable de Vue)

```javascript
// composables/useAuth.js
import { ref } from 'vue';

const API_BASE = 'https://salumedx-rest.onrender.com';

export function useAuth() {
  const isAuthenticated = ref(!!localStorage.getItem('access_token'));
  
  async function apiRequest(endpoint, options = {}) {
    const token = localStorage.getItem('access_token');
    
    const config = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
        ...(token && { 'Authorization': `Bearer ${token}` })
      }
    };
    
    let response = await fetch(`${API_BASE}${endpoint}`, config);
    
    // Si el token expiró, refrescar y reintentar
    if (response.status === 401 && token) {
      const refreshed = await refreshToken();
      if (refreshed) {
        config.headers['Authorization'] = `Bearer ${localStorage.getItem('access_token')}`;
        response = await fetch(`${API_BASE}${endpoint}`, config);
      }
    }
    
    return response;
  }
  
  async function login(username, password) {
    const response = await fetch(`${API_BASE}/signin/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    
    const data = await response.json();
    
    if (data.success) {
      localStorage.setItem('access_token', data.access);
      localStorage.setItem('refresh_token', data.refresh);
      localStorage.setItem('user', JSON.stringify(data.user));
      isAuthenticated.value = true;
    }
    
    return data;
  }
  
  async function refreshToken() {
    const refresh = localStorage.getItem('refresh_token');
    if (!refresh) return false;
    
    const response = await fetch(`${API_BASE}/token/refresh/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh })
    });
    
    if (response.ok) {
      const data = await response.json();
      localStorage.setItem('access_token', data.access);
      return true;
    }
    
    logout();
    return false;
  }
  
  function logout() {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('user');
    isAuthenticated.value = false;
  }
  
  return {
    isAuthenticated,
    apiRequest,
    login,
    logout,
    refreshToken
  };
}
```

**Uso:**
```vue
<script setup>
import { useAuth } from '@/composables/useAuth';

const { apiRequest, login } = useAuth();

async function getRecetas() {
  const response = await apiRequest('/recetas/');
  const data = await response.json();
  console.log(data);
}

async function handleLogin() {
  const result = await login(username.value, password.value);
  if (result.success) {
    router.push('/dashboard');
  }
}
</script>
```

---

## 🔧 Código para Sinatra GraphQL

Sinatra ahora es **mucho más simple** porque no necesita manejar cookies:

```ruby
require 'sinatra'
require 'sinatra/cross_origin'
require 'net/http'
require 'json'

configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = 'http://localhost:5173'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
end

options '*' do
  200
end

# Helper para llamar a Django con JWT
def call_django(path, method: :get, body: nil, token: nil)
  uri = URI("https://salumedx-rest.onrender.com#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = case method
  when :get then Net::HTTP::Get.new(uri)
  when :post then Net::HTTP::Post.new(uri)
  end
  
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{token}" if token  # ✅ Enviar JWT
  request.body = body.to_json if body
  
  http.request(request)
end

# GraphQL endpoint
post '/graphql' do
  content_type :json
  
  # Extraer token del header Authorization
  token = request.env['HTTP_AUTHORIZATION']&.gsub('Bearer ', '')
  
  halt 401, { error: 'No autenticado' }.to_json unless token
  
  query = JSON.parse(request.body.read)
  
  # Ejemplo: query de recetas
  if query['query'].include?('recetas')
    response = call_django('/recetas/', token: token)
    response.body
  end
end
```

**Ya NO necesitas:**
- ❌ `enable :sessions`
- ❌ Guardar cookies en sesión
- ❌ Extraer cookies de Django
- ❌ Enviar cookies en cada petición

**Simplemente:**
- ✅ Recibir token del frontend en header `Authorization`
- ✅ Pasarlo a Django en el mismo header
- ✅ Listo

---

## 📊 Comparación

| Aspecto | Cookies (Antes) | JWT (Ahora) |
|---------|-----------------|-------------|
| Cross-domain | ❌ Problemas SameSite | ✅ Sin problemas |
| Almacenamiento | Server (sesiones) | Client (localStorage) |
| Complejidad | 🔴 Alta (Sinatra maneja cookies) | 🟢 Baja (solo headers) |
| Seguridad | 🟡 HTTP-only cookies | 🟡 localStorage (vulnerable a XSS) |
| CSRF | ⚠️ Necesita protección | ✅ No aplica |
| Escalabilidad | ❌ Sesiones en DB/memoria | ✅ Stateless |

---

## ⚠️ Importante

1. **Tokens expiran:**
   - Access token: 5 horas
   - Refresh token: 7 días
   - Implementa lógica de refresh automático

2. **Seguridad:**
   - NO expongas tokens en URLs
   - Usa HTTPS en producción (ya lo tienes)
   - Valida tokens en cada petición sensible

3. **Logout:**
   - Simplemente elimina tokens del localStorage
   - No hay endpoint `/logout/` necesario (opcional blacklist)

---

## 🚀 Deploy

1. Instalar nueva dependencia en local:
```bash
pip install djangorestframework-simplejwt==5.3.1
```

2. Hacer push:
```bash
git add .
git commit -m "Migrate from session authentication to JWT"
git push
```

3. Render detectará el nuevo `requirements.txt` y redeploy automáticamente

---

## ✅ Checklist de Migración

### Backend (Django):
- [x] Instalar `djangorestframework-simplejwt`
- [x] Configurar JWT en `settings.py`
- [x] Actualizar `/signin/` para devolver tokens
- [x] Actualizar `/signup/` para devolver tokens
- [x] Agregar `/token/refresh/` endpoint
- [x] Eliminar código de sesiones/cookies
- [ ] Hacer push a Render

### Frontend (Vue):
- [ ] Actualizar llamada a `/signin/` (guardar tokens)
- [ ] Enviar `Authorization: Bearer <token>` en peticiones
- [ ] Implementar refresh token automático
- [ ] Manejar expiración (logout si refresh falla)
- [ ] Eliminar código de cookies

### Sinatra (GraphQL):
- [ ] Simplificar: eliminar manejo de sesiones
- [ ] Recibir token en header `Authorization`
- [ ] Pasar token a Django en mismo header
- [ ] Eliminar código de cookies

---

**¡Listo para JWT! 🎉**
