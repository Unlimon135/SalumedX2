# API de Administración - Documentación para Frontend Vue

## Autenticación

Todos los endpoints bajo `/api/admin/*` requieren:
1. **Token JWT válido** en el header `Authorization`
2. **Usuario con is_staff=True** (staff/admin)

### Cómo obtener el token

```javascript
// 1. Login (obtener JWT)
const response = await fetch('https://tu-servidor.com/signin/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'admin_user',
    password: 'password123'
  })
})

const data = await response.json()
const token = data.access  // Token JWT
const refreshToken = data.refresh

// Guardar en localStorage o Vuex/Pinia
localStorage.setItem('access_token', token)
localStorage.setItem('refresh_token', refreshToken)
```

### Cómo usar el token en requests

```javascript
const token = localStorage.getItem('access_token')

const response = await fetch('https://tu-servidor.com/api/admin/productos/', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
})

const data = await response.json()
```

### Refresh del token (cuando expire)

```javascript
const refreshToken = localStorage.getItem('refresh_token')

const response = await fetch('https://tu-servidor.com/token/refresh/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ refresh: refreshToken })
})

const data = await response.json()
localStorage.setItem('access_token', data.access)
```

---

## Endpoints Disponibles

### 1. Listar Productos con Precios

**GET** `/api/admin/productos/`

Devuelve todos los productos con sus precios por farmacia (igual formato que `/productos/` público).

**Query params (opcionales):**
- `?search=paracetamol` - Busca en nombre genérico, comercial, principio activo
- `?categoria=Analgésicos` - Filtra por categoría
- `?con_precios=true` - Solo productos que tienen precios registrados

**Ejemplo:**
```javascript
const response = await fetch('https://tu-servidor.com/api/admin/productos/?search=ibuprofeno', {
  headers: { 'Authorization': `Bearer ${token}` }
})

const data = await response.json()
/*
{
  "success": true,
  "productos": [
    {
      "id_producto": 1,
      "nombre_generico": "Ibuprofeno",
      "nombre_comercial": "Advil",
      "precios_por_farmacia": [
        {
          "id_producto_farmacia": 5,
          "farmacia": {
            "id_farmacia": 1,
            "nombre_comercial": "Farmacia Cruz Azul"
          },
          "precio": "2.50",
          "disponible": true
        }
      ],
      "precio_minimo": 2.50,
      "precio_maximo": 3.80,
      "precio_promedio": 3.15
    }
  ],
  "total": 1,
  "user": "admin_username"
}
*/
```

---

### 2. Listar Farmacias

**GET** `/api/admin/farmacias/`

Devuelve todas las farmacias registradas.

**Ejemplo:**
```javascript
const response = await fetch('https://tu-servidor.com/api/admin/farmacias/', {
  headers: { 'Authorization': `Bearer ${token}` }
})

const data = await response.json()
/*
{
  "success": true,
  "farmacias": [
    {
      "id_farmacia": 1,
      "nombre_comercial": "Farmacia Cruz Azul",
      "direccion": "Calle Principal 123",
      "telefono": "0999999999"
    }
  ],
  "total": 1
}
*/
```

---

### 3. Gestionar Precios de Productos en Farmacias

#### GET - Listar precios

**GET** `/api/admin/producto-farmacia/`

**Query params (opcionales):**
- `?producto=1` - Filtra por producto
- `?farmacia=2` - Filtra por farmacia

**Ejemplo:**
```javascript
const response = await fetch('https://tu-servidor.com/api/admin/producto-farmacia/?producto=1', {
  headers: { 'Authorization': `Bearer ${token}` }
})

const data = await response.json()
/*
{
  "success": true,
  "precios": [
    {
      "id_producto_farmacia": 5,
      "producto": { ... },
      "farmacia": { ... },
      "precio": "2.50",
      "disponible": true,
      "fecha_actualizacion": "2025-11-12T10:30:00Z"
    }
  ],
  "total": 1
}
*/
```

#### POST - Crear o actualizar precio

**POST** `/api/admin/producto-farmacia/`

**Body (JSON):**
```json
{
  "producto": 1,
  "farmacia": 2,
  "precio": "15.50",
  "disponible": true
}
```

**Ejemplo:**
```javascript
const response = await fetch('https://tu-servidor.com/api/admin/producto-farmacia/', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    producto: 1,
    farmacia: 2,
    precio: "15.50",
    disponible: true
  })
})

const data = await response.json()
/*
{
  "success": true,
  "created": true,  // false si fue actualización
  "producto_farmacia": {
    "id_producto_farmacia": 10,
    "producto": { ... },
    "farmacia": { ... },
    "precio": "15.50",
    "disponible": true
  }
}
*/
```

---

### 4. Eliminar Precio

**DELETE** `/api/admin/producto-farmacia/<id>/`

**Ejemplo:**
```javascript
const id = 10  // ID del ProductoFarmacia a eliminar

const response = await fetch(`https://tu-servidor.com/api/admin/producto-farmacia/${id}/`, {
  method: 'DELETE',
  headers: { 'Authorization': `Bearer ${token}` }
})

const data = await response.json()
/*
{
  "success": true,
  "message": "Precio eliminado correctamente"
}
*/
```

---

### 5. Estadísticas del Sistema

**GET** `/api/admin/stats/`

Devuelve estadísticas generales del sistema.

**Ejemplo:**
```javascript
const response = await fetch('https://tu-servidor.com/api/admin/stats/', {
  headers: { 'Authorization': `Bearer ${token}` }
})

const data = await response.json()
/*
{
  "success": true,
  "stats": {
    "productos": 150,
    "farmacias": 25,
    "precios_registrados": 1200,
    "productos_sin_precio": 30,
    "pacientes": 500,
    "medicos": 50,
    "recetas": 800
  }
}
*/
```

---

## Manejo de Errores

### 401 Unauthorized
Token inválido o expirado → Hacer refresh o re-login

```javascript
if (response.status === 401) {
  // Intentar refresh
  await refreshToken()
  // O redirigir a login
}
```

### 403 Forbidden
Usuario no es staff → El usuario debe tener `is_staff=True` en Django admin

### 404 Not Found
Recurso no encontrado

### 500 Internal Server Error
Error del servidor → Revisar logs

---

## Ejemplo Completo en Vue 3 (Composition API)

```vue
<script setup>
import { ref, onMounted } from 'vue'

const productos = ref([])
const token = ref(localStorage.getItem('access_token'))

const fetchProductos = async () => {
  try {
    const response = await fetch('https://tu-servidor.com/api/admin/productos/', {
      headers: { 'Authorization': `Bearer ${token.value}` }
    })
    
    if (!response.ok) {
      if (response.status === 401) {
        // Token expirado, redirigir a login
        router.push('/login')
        return
      }
      throw new Error('Error al cargar productos')
    }
    
    const data = await response.json()
    productos.value = data.productos
  } catch (error) {
    console.error('Error:', error)
  }
}

const crearPrecio = async (productoId, farmaciaId, precio) => {
  try {
    const response = await fetch('https://tu-servidor.com/api/admin/producto-farmacia/', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token.value}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        producto: productoId,
        farmacia: farmaciaId,
        precio: precio,
        disponible: true
      })
    })
    
    if (!response.ok) throw new Error('Error al crear precio')
    
    const data = await response.json()
    console.log('Precio creado:', data)
    
    // Recargar productos
    await fetchProductos()
  } catch (error) {
    console.error('Error:', error)
  }
}

onMounted(() => {
  fetchProductos()
})
</script>

<template>
  <div>
    <h1>Productos Admin</h1>
    <ul>
      <li v-for="p in productos" :key="p.id_producto">
        {{ p.nombre_comercial }} - ${{ p.precio_promedio }}
      </li>
    </ul>
  </div>
</template>
```

---

## Notas Importantes

1. **CORS**: Si tu frontend Vue está en un dominio diferente (ej. `localhost:5173`), asegúrate de que el backend Django tenga CORS configurado correctamente con `django-cors-headers`.

2. **CSRF**: No necesitas CSRF tokens para endpoints JWT. Los endpoints `/api/admin/*` usan JWT puro.

3. **Seguridad**: 
   - Nunca expongas los tokens en URLs
   - Guarda los tokens en `localStorage` o mejor en `httpOnly` cookies
   - Implementa logout que limpie los tokens

4. **Diferencia con `/admin/`**:
   - `/admin/` = Interfaz web de Django (HTML, requiere sesión cookie)
   - `/api/admin/*` = API JSON para Vue (requiere JWT)
