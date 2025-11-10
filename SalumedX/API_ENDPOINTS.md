# 📋 Documentación de Endpoints - API SalumedX

**Base URL:** `https://salumedx-rest.onrender.com`

---

## 🔐 Autenticación

### 1. **POST** `/signin/` - Iniciar sesión
**Descripción:** Autentica al usuario y crea una sesión con cookies.

**Permisos:** 🌍 Público (AllowAny)

**Body (JSON):**
```json
{
  "username": "string",
  "password": "string"
}
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Login exitoso"
}
```

**Respuesta error (400):**
```json
{
  "success": false,
  "error": "El usuario o la contraseña son incorrectos"
}
```

**Cookies recibidas:**
- `sessionid` - Cookie de sesión HTTP-only
- `csrftoken` - Token CSRF

---

### 2. **POST** `/signup/` - Registrar usuario
**Descripción:** Crea un nuevo usuario (médico o paciente) y lo autentica automáticamente.

**Permisos:** 🌍 Público (AllowAny)

**Body (JSON) - Médico:**
```json
{
  "username": "string",
  "password1": "string",
  "password2": "string",
  "first_name": "string",
  "last_name": "string",
  "email": "string",
  "tipo_usuario": "medico",
  "numero_licencia": "string",
  "institucion": "string",
  "ubicacion_consultorio": "string"
}
```

**Body (JSON) - Paciente:**
```json
{
  "username": "string",
  "password1": "string",
  "password2": "string",
  "first_name": "string",
  "last_name": "string",
  "email": "string",
  "tipo_usuario": "paciente",
  "fecha_nacimiento": "YYYY-MM-DD",
  "cedula": "string",
  "direccion": "string",
  "telefono": "string"
}
```

**Respuesta exitosa (201):**
```json
{
  "success": true,
  "tipo_usuario": "medico|paciente",
  "perfil": {
    "id": 1,
    "user": {...},
    // Campos específicos del perfil
  }
}
```

**Respuesta error (400):**
```json
{
  "success": false,
  "error": "Las contraseñas no coinciden"
}
```

---

### 3. **POST** `/logout/` - Cerrar sesión
**Descripción:** Cierra la sesión del usuario autenticado.

**Permisos:** 🔒 Autenticado (IsAuthenticated)

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Sesión cerrada"
}
```

---

## 👤 Perfil de Usuario

### 4. **GET** `/tasks/` - Obtener perfil actual
**Descripción:** Devuelve información completa del usuario autenticado (médico o paciente).

**Permisos:** 🔒 Autenticado (IsAuthenticated)

**Respuesta exitosa (200):**
```json
{
  "tipo_usuario": "medico|paciente",
  "perfil": {
    "id": 1,
    "user": {
      "id": 1,
      "username": "string",
      "first_name": "string",
      "last_name": "string",
      "email": "string"
    },
    // Campos específicos del perfil
  }
}
```

---

### 5. **GET** `/` - Home (Mensaje de bienvenida)
**Descripción:** Endpoint raíz que confirma que la API está funcionando.

**Permisos:** 🌍 Público (AllowAny)

**Respuesta (200):**
```json
{
  "message": "Bienvenido a la API de SalumedX"
}
```

---

## 📝 Recetas Médicas

### 6. **GET** `/recetas/` - Listar recetas
**Descripción:** 
- **Médicos:** Ven las recetas que ellos escribieron
- **Pacientes:** Ven las recetas que les escribieron

**Permisos:** 🔒 Autenticado (IsAuthenticated)

**Query Params opcionales:**
- `id` - Filtra por ID de receta específica
- `paciente` - (Solo médicos) Filtra por ID de paciente
- `fecha` - Filtra por fecha de emisión (YYYY-MM-DD)

**Ejemplos:**
```
GET /recetas/
GET /recetas/?id=5
GET /recetas/?paciente=3
GET /recetas/?fecha=2025-11-09
```

**Respuesta exitosa (200):**
```json
{
  "recetas": [
    {
      "id_receta": 1,
      "medico": {...},
      "paciente": {...},
      "fecha_emision": "2025-11-09",
      "diagnostico": "string",
      "observaciones": "string",
      "ubicacion_emision": "string",
      "detalles": [...]
    }
  ],
  "total": 5
}
```

**Respuesta de receta específica:**
```json
{
  "receta": {
    "id_receta": 5,
    "medico": {...},
    "paciente": {...},
    "detalles": [...]
  }
}
```

---

### 7. **POST** `/recetas/` - Crear receta
**Descripción:** Crea una nueva receta médica (solo médicos).

**Permisos:** 🔒 Autenticado + Médico

**Body (JSON):**
```json
{
  "paciente": 3,
  "fecha_emision": "2025-11-09",
  "diagnostico": "Gripe común",
  "observaciones": "Reposo y abundante líquido",
  "ubicacion_emision": "Consultorio Central",
  "detalles": [
    {
      "producto": 1,
      "cantidad": 2,
      "dosis": "500mg cada 8 horas",
      "presentacion": "Tabletas",
      "duracion_tratamiento": "5 días",
      "instrucciones": "Tomar después de las comidas"
    }
  ]
}
```

**Respuesta exitosa (201):**
```json
{
  "success": true,
  "receta": {
    "id_receta": 10,
    "medico": {...},
    "paciente": {...},
    "detalles": [...]
  }
}
```

**Respuesta error (403) - Paciente intenta crear:**
```json
{
  "error": "Solo los médicos pueden crear recetas."
}
```

---

## 💊 Catálogo Público

### 8. **GET** `/productos/` - Listar productos
**Descripción:** Devuelve todos los productos disponibles.

**Permisos:** 🌍 Público (AllowAny)

**Query Params opcionales:**
- `id` - Filtra por ID de producto
- `categoria` - Filtra por categoría
- `requiere_receta` - Filtra por si requiere receta (true/false)
- `search` - Busca en nombre genérico, comercial o principio activo

**Ejemplos:**
```
GET /productos/
GET /productos/?id=1
GET /productos/?categoria=Analgésicos
GET /productos/?requiere_receta=true
GET /productos/?search=paracetamol
```

**Respuesta exitosa (200):**
```json
{
  "productos": [
    {
      "id_producto": 1,
      "nombre_generico": "Paracetamol",
      "nombre_comercial": "Tylenol",
      "principio_activo": "Paracetamol",
      "categoria": "Analgésicos",
      "presentacion": "Tabletas",
      "concentracion": "500mg",
      "requiere_receta": false
    }
  ],
  "total": 15
}
```

---

### 9. **GET** `/farmacias/` - Listar farmacias
**Descripción:** Devuelve todas las farmacias disponibles.

**Permisos:** 🌍 Público (AllowAny)

**Query Params opcionales:**
- `id` - Filtra por ID de farmacia
- `search` - Busca en nombre comercial

**Ejemplos:**
```
GET /farmacias/
GET /farmacias/?id=1
GET /farmacias/?search=cruz
```

**Respuesta exitosa (200):**
```json
{
  "farmacias": [
    {
      "id_farmacia": 1,
      "nombre_comercial": "Farmacia Cruz Azul",
      "horario_atencion": "Lun-Vie 8am-8pm"
    }
  ],
  "total": 8
}
```

---

### 10. **GET** `/sucursales/` - Listar sucursales
**Descripción:** Devuelve todas las sucursales de farmacias con su ubicación.

**Permisos:** 🌍 Público (AllowAny)

**Query Params opcionales:**
- `id` - Filtra por ID de sucursal
- `farmacia` - Filtra por ID de farmacia
- `ubicacion` - Busca en ubicación

**Ejemplos:**
```
GET /sucursales/
GET /sucursales/?id=1
GET /sucursales/?farmacia=2
GET /sucursales/?ubicacion=Guayaquil
```

**Respuesta exitosa (200):**
```json
{
  "sucursales": [
    {
      "id_sucursal": 1,
      "farmacia": {
        "id_farmacia": 1,
        "nombre_comercial": "Farmacia Cruz Azul",
        "horario_atencion": "Lun-Vie 8am-8pm"
      },
      "ubicacion": "Centro Comercial El Fortín",
      "longitud": -79.123456,
      "latitud": -2.123456
    }
  ],
  "total": 12
}
```

---

## 🔍 Información de Usuarios

### 11. **GET** `/paciente-info/` - Información de pacientes
**Descripción:** Devuelve información pública de pacientes.

**Permisos:** 🌍 Público (AllowAny)

**Query Params opcionales:**
- `id` - Filtra por ID de paciente

**Ejemplos:**
```
GET /paciente-info/
GET /paciente-info/?id=3
```

**Respuesta exitosa (200):**
```json
{
  "pacientes": [
    {
      "paciente_id": 3,
      "user_id": 5,
      "username": "juan_perez",
      "nombre_completo": "Juan Pérez",
      "email": "juan@example.com",
      "cedula": "0912345678"
    }
  ],
  "total": 10
}
```

**Respuesta de paciente específico:**
```json
{
  "paciente_id": 3,
  "user_id": 5,
  "username": "juan_perez",
  "nombre_completo": "Juan Pérez",
  "email": "juan@example.com",
  "cedula": "0912345678",
  "telefono": "0999123456"
}
```

---

### 12. **GET** `/medico-info/` - Información de médicos
**Descripción:** Devuelve información pública de médicos.

**Permisos:** 🌍 Público (AllowAny)

**Query Params opcionales:**
- `id` - Filtra por ID de médico

**Ejemplos:**
```
GET /medico-info/
GET /medico-info/?id=1
```

**Respuesta exitosa (200):**
```json
{
  "medicos": [
    {
      "medico_id": 1,
      "user_id": 2,
      "username": "dr_garcia",
      "nombre_completo": "Dr. Carlos García",
      "email": "garcia@example.com",
      "numero_licencia": "MD-12345"
    }
  ],
  "total": 5
}
```

**Respuesta de médico específico:**
```json
{
  "medico_id": 1,
  "user_id": 2,
  "username": "dr_garcia",
  "nombre_completo": "Dr. Carlos García",
  "email": "garcia@example.com",
  "numero_licencia": "MD-12345",
  "institucion": "Hospital General"
}
```

---

## 🏥 Detalles de Prescripción

### 13. **GET** `/detalle-prescripcion/` - Listar prescripciones
**Descripción:** 
- **Médicos:** Ven prescripciones de sus recetas
- **Pacientes:** Ven prescripciones de sus recetas

**Permisos:** 🔒 Autenticado (IsAuthenticated)

**Query Params opcionales:**
- `farmacia` - Filtra por ID de farmacia
- `producto` - Filtra por ID de producto
- `detalle_receta` - Filtra por ID de detalle de receta

**Ejemplos:**
```
GET /detalle-prescripcion/
GET /detalle-prescripcion/?farmacia=1
GET /detalle-prescripcion/?producto=5
```

**Respuesta exitosa (200):**
```json
{
  "detalle_prescripciones": [
    {
      "id_detalle_prescripcion": 1,
      "detalle_receta": {...},
      "farmacia": {...},
      "producto": {...},
      "precio_encontrado": 12.50,
      "distancia": 2.5,
      "fecha_consulta": "2025-11-09T10:30:00Z",
      "fuente": "Página web oficial"
    }
  ],
  "total": 3
}
```

**Respuesta error (401) - No autenticado:**
```json
{
  "error": "Debe autenticarse para consultar prescripciones."
}
```

---

### 14. **POST** `/detalle-prescripcion/` - Crear prescripción
**Descripción:** Crea un nuevo detalle de prescripción (precio/farmacia de un producto).

**Permisos:** 🌍 Público (AllowAny) - ⚠️ Considera cambiar a IsAuthenticated

**Body (JSON):**
```json
{
  "detalle_receta": 1,
  "farmacia": 2,
  "producto": 5,
  "precio_encontrado": 12.50,
  "distancia": 2.5,
  "fuente": "Página web oficial"
}
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "detalle_prescripcion": {
    "id_detalle_prescripcion": 10,
    "detalle_receta": {...},
    "farmacia": {...},
    "producto": {...},
    "precio_encontrado": 12.50,
    "distancia": 2.5,
    "fuente": "Página web oficial"
  }
}
```

---

## 🔑 Resumen de Permisos

| Endpoint | Método | Permiso | Descripción |
|----------|--------|---------|-------------|
| `/` | GET | 🌍 Público | Mensaje de bienvenida |
| `/signin/` | POST | 🌍 Público | Login |
| `/signup/` | POST | 🌍 Público | Registro |
| `/logout/` | POST | 🔒 Autenticado | Cerrar sesión |
| `/tasks/` | GET | 🔒 Autenticado | Perfil del usuario |
| `/recetas/` | GET | 🔒 Autenticado | Ver recetas (médico o paciente) |
| `/recetas/` | POST | 🔒 Solo Médicos | Crear receta |
| `/productos/` | GET | 🌍 Público | Catálogo de productos |
| `/farmacias/` | GET | 🌍 Público | Listado de farmacias |
| `/sucursales/` | GET | 🌍 Público | Sucursales con ubicación |
| `/paciente-info/` | GET | 🌍 Público | Info de pacientes |
| `/medico-info/` | GET | 🌍 Público | Info de médicos |
| `/detalle-prescripcion/` | GET | 🔒 Autenticado | Ver prescripciones |
| `/detalle-prescripcion/` | POST | 🌍 Público | Crear prescripción |

---

## 🍪 Autenticación por Cookies

Todos los endpoints que requieren autenticación usan **cookies de sesión**:

1. **Login:** `POST /signin/` devuelve cookies `sessionid` y `csrftoken`
2. **Peticiones autenticadas:** Incluir `credentials: 'include'` en fetch
3. **POST/PUT/DELETE:** Incluir header `X-CSRFToken` con el valor de la cookie `csrftoken`

### Ejemplo en JavaScript:

```javascript
// Login
const login = await fetch('https://salumedx-rest.onrender.com/signin/', {
  method: 'POST',
  credentials: 'include',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username, password })
});

// Petición autenticada
const recetas = await fetch('https://salumedx-rest.onrender.com/recetas/', {
  credentials: 'include'
});

// POST con CSRF
function getCookie(name) {
  return document.cookie.split('; ')
    .find(row => row.startsWith(name + '='))
    ?.split('=')[1];
}

const crear = await fetch('https://salumedx-rest.onrender.com/recetas/', {
  method: 'POST',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRFToken': getCookie('csrftoken')
  },
  body: JSON.stringify({...})
});
```

---

## 📌 Notas Importantes

1. **Base URL:** `https://salumedx-rest.onrender.com`
2. **Autenticación:** SessionAuthentication con cookies HTTP-only
3. **CORS:** Habilitado con `CORS_ALLOW_CREDENTIALS = True`
4. **CSRF Protection:** Requerido para POST/PUT/DELETE
5. **Formato:** Todas las respuestas son JSON
6. **Errores:** Devuelven JSON con campo `error` y status code apropiado

---

## 🐛 Códigos de Error Comunes

| Código | Significado | Solución |
|--------|-------------|----------|
| 400 | Bad Request | Datos inválidos o faltantes |
| 401 | Unauthorized | No autenticado, hacer login |
| 403 | Forbidden | Sin permisos (ej. paciente creando receta) |
| 404 | Not Found | Recurso no existe |
| 500 | Server Error | Error interno, contactar soporte |

---

**Última actualización:** Noviembre 9, 2025  
**Versión API:** 1.0  
**Desarrollado por:** Equipo SalumedX
