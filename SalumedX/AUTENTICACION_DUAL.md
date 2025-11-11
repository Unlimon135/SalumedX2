# 🔐 Autenticación Dual: JWT + Session

## ✅ Problema Resuelto

**Antes:** El login no funcionaba porque la API solo aceptaba JWT pero el frontend enviaba cookies de sesión.

**Ahora:** Soporte dual - la API acepta **ambos** métodos:
- ✅ JWT (Bearer tokens) → Para Sinatra/GraphQL y APIs externas
- ✅ Session (Cookies) → Para frontend local durante migración

---

## 🔧 Cambios Realizados

### **1. `settings.py` - Autenticación Dual**
```python
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',        # JWT
        'rest_framework.authentication.SessionAuthentication',  # ⬅️ NUEVO
    ],
}

# Configuración de sesiones
SESSION_COOKIE_SECURE = False  # True en producción
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'
SESSION_COOKIE_AGE = 18000  # 5 horas
```

### **2. `signin_view.py` - Login Mejorado**
Ahora el login hace 2 cosas:
1. ✅ Crea sesión con cookies (para frontend local)
2. ✅ Devuelve tokens JWT (para Sinatra/APIs)

**Respuesta mejorada:**
```json
{
  "success": true,
  "message": "Login exitoso",
  "access": "eyJ0eXAi...",     // Token JWT de acceso
  "refresh": "eyJ0eXAi...",    // Token JWT de refresco
  "user": {
    "id": 1,
    "username": "medico1",
    "email": "medico1@example.com",
    "first_name": "Juan",
    "last_name": "Pérez",
    "tipo_usuario": "medico",    // ⬅️ NUEVO
    "perfil": {                  // ⬅️ NUEVO
      "numero_licencia": "12345",
      "institucion": "Hospital Central",
      "ubicacion_consultorio": "Consultorio 101"
    }
  }
}
```

---

## 🎯 Cómo Funciona Ahora

### **Opción A: Frontend con Cookies (actual)**

Tu frontend puede seguir usando cookies sin cambios:

```javascript
// Login
fetch('http://localhost:8000/signin/', {
  method: 'POST',
  credentials: 'include',  // ✅ Envía cookies automáticamente
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'medico1', password: 'pass123' })
})
.then(res => res.json())
.then(data => {
  console.log(`Bienvenido ${data.user.first_name} ${data.user.last_name}`);
  console.log(`Tipo: ${data.user.tipo_usuario}`);
  // La sesión está guardada en cookies, no necesitas hacer nada más
});

// Peticiones protegidas (automáticamente usa cookies)
fetch('http://localhost:8000/recetas/', {
  credentials: 'include'  // ✅ Envía cookies con cada petición
})
.then(res => res.json())
.then(data => console.log(data.recetas));
```

---

### **Opción B: Sinatra/GraphQL con JWT**

Sinatra puede usar JWT sin preocuparse por cookies:

```ruby
# Login desde Sinatra
url = URI("https://salumedx-rest.onrender.com/signin/")
request = Net::HTTP::Post.new(url)
request['Content-Type'] = 'application/json'
request.body = { username: 'medico1', password: 'pass123' }.to_json

response = http.request(request)
data = JSON.parse(response.body)

# Guardar token
token = data['access']

# Usar token en peticiones
request = Net::HTTP::Get.new(URI("https://salumedx-rest.onrender.com/recetas/"))
request['Authorization'] = "Bearer #{token}"
response = http.request(request)
```

---

## 📋 Flujo de Autenticación

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │
       ▼
POST /signin/
{ username, password }
       │
       ▼
┌──────────────────┐
│  Django Backend  │
│  authenticate()  │
└──────┬───────────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
   login(user)    RefreshToken.for_user()
   (sesión)          (JWT tokens)
       │                 │
       ▼                 ▼
Set-Cookie:        { access, refresh }
sessionid=...
       │                 │
       └─────────┬───────┘
                 ▼
        Response completo
        ├─ Cookies (sesión)
        └─ JSON (tokens + user)
```

---

## 🚀 Ventajas del Sistema Dual

| Característica | JWT | Session (Cookies) |
|----------------|-----|-------------------|
| **Stateless** | ✅ Sí | ❌ No (requiere BD) |
| **Cross-domain** | ✅ Funciona | ⚠️ Limitado |
| **Móviles/APIs** | ✅ Ideal | ❌ Complicado |
| **Browsers** | ⚠️ Manual | ✅ Automático |
| **Expiración** | ✅ 5 horas | ✅ 5 horas |
| **Refresh** | ✅ Token | ❌ Requiere re-login |

---

## 🎨 Mensaje de Bienvenida Personalizado

El login ahora devuelve:
- `tipo_usuario`: "medico" o "paciente"
- `perfil`: Datos específicos del tipo de usuario

**Ejemplo en Vue/React:**
```javascript
const response = await fetch('/signin/', {
  method: 'POST',
  credentials: 'include',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username, password })
});

const data = await response.json();

if (data.success) {
  const { user } = data;
  
  // Mensaje personalizado
  let mensaje = `Bienvenido/a ${user.first_name} ${user.last_name}`;
  
  if (user.tipo_usuario === 'medico') {
    mensaje += `\nInstitución: ${user.perfil.institucion}`;
  } else if (user.tipo_usuario === 'paciente') {
    mensaje += `\nCédula: ${user.perfil.cedula}`;
  }
  
  alert(mensaje);
  
  // Redirigir según tipo
  if (user.tipo_usuario === 'medico') {
    window.location.href = '/dashboard-medico';
  } else {
    window.location.href = '/dashboard-paciente';
  }
}
```

---

## ✅ Checklist de Funcionamiento

### **Login Correcto:**
- [x] Se crea cookie `sessionid`
- [x] Se devuelven tokens JWT (`access` y `refresh`)
- [x] Se devuelve información del usuario con `tipo_usuario`
- [x] Se devuelve `perfil` con datos específicos

### **Endpoints Protegidos:**
- [x] `/recetas/` acepta cookies de sesión
- [x] `/recetas/` acepta JWT Bearer token
- [x] `/tasks/` acepta cookies de sesión
- [x] `/tasks/` acepta JWT Bearer token

### **Endpoints Públicos (sin cambios):**
- [x] `/productos/`
- [x] `/farmacias/`
- [x] `/comparar-precios/`
- [x] `/consultas-producto/`

---

## 🧪 Cómo Probar

### **Test 1: Login con Cookies**
```bash
curl -X POST http://localhost:8000/signin/ \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"username":"medico1","password":"pass123"}'

# Verificar que se creó la cookie
cat cookies.txt | grep sessionid

# Usar la cookie en petición protegida
curl http://localhost:8000/recetas/ \
  -b cookies.txt
```

### **Test 2: Login con JWT**
```bash
# Login y guardar token
TOKEN=$(curl -X POST http://localhost:8000/signin/ \
  -H "Content-Type: application/json" \
  -d '{"username":"medico1","password":"pass123"}' \
  | jq -r '.access')

# Usar token en petición protegida
curl http://localhost:8000/recetas/ \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📌 Migración Futura (Opcional)

Cuando el frontend esté listo para usar solo JWT:

1. Eliminar `SessionAuthentication` de `settings.py`
2. Eliminar `login(request, user)` de `signin_view.py`
3. Eliminar configuración de `SESSION_COOKIE_*`

Por ahora, **el sistema dual funciona perfectamente** para ambos casos. 🎉

---

## 🆘 Troubleshooting

### **Problema: "Authentication credentials were not provided"**
**Causa:** No se envían ni cookies ni JWT Bearer token.

**Solución:**
```javascript
// Opción A: Agregar credentials
fetch('/recetas/', { credentials: 'include' })

// Opción B: Agregar Authorization header
fetch('/recetas/', {
  headers: { 'Authorization': `Bearer ${token}` }
})
```

### **Problema: "Cookie 'sessionid' is rejected"**
**Causa:** SameSite policy en cross-origin.

**Solución:** Usar JWT en lugar de cookies para peticiones cross-domain.

### **Problema: "Invalid token" con JWT**
**Causa:** Token expirado o inválido.

**Solución:**
```javascript
// Usar el refresh token para obtener nuevo access token
fetch('/token/refresh/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ refresh: refreshToken })
})
```

---

## 📊 Estado Actual

- ✅ **Login funciona** (crea sesión + devuelve JWT)
- ✅ **Endpoints protegidos funcionan** con cookies
- ✅ **Endpoints protegidos funcionan** con JWT
- ✅ **Mensaje personalizado** con tipo_usuario y perfil
- ✅ **Compatible con Sinatra** usando JWT
- ✅ **Compatible con frontend local** usando cookies

**¡Todo funcionando! 🎉**
