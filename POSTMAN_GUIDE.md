# 📮 Guía Completa de Endpoints - Postman

**Base URL:** `http://127.0.0.1:8002`

---

## 🔐 AUTENTICACIÓN

### 1. Registrar Farmacéutico
**POST** `http://127.0.0.1:8002/auth/register/`

**Headers:**
```
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "email": "farmaceutico@farmacia.com",
  "username": "farmaceutico1",
  "password": "Password123!",
  "password2": "Password123!",
  "tipo_usuario": "farmaceutico",
  "first_name": "Juan",
  "last_name": "Pérez",
  "telefono": "0991234567",
  "direccion": "Av. Principal 123, Manta"
}
```

**Respuesta esperada (201):**
```json
{
  "message": "Usuario registrado exitosamente",
  "user": {
    "id": 1,
    "email": "farmaceutico@farmacia.com",
    "username": "farmaceutico1",
    "tipo_usuario": "farmaceutico",
    "first_name": "Juan",
    "last_name": "Pérez",
    "telefono": "0991234567",
    "direccion": "Av. Principal 123, Manta"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

---

### 2. Registrar Cliente
**POST** `http://127.0.0.1:8002/auth/register/`

**Body (raw JSON):**
```json
{
  "email": "cliente@gmail.com",
  "username": "cliente1",
  "password": "Password123!",
  "password2": "Password123!",
  "tipo_usuario": "cliente",
  "first_name": "María",
  "last_name": "García",
  "telefono": "0987654321",
  "direccion": "Calle 10 de Agosto, Portoviejo"
}
```

---

### 3. Login (Iniciar Sesión)
**POST** `http://127.0.0.1:8002/auth/login/`

**Body (raw JSON):**
```json
{
  "email": "farmaceutico@farmacia.com",
  "password": "Password123!"
}
```

**Respuesta esperada (200):**
```json
{
  "message": "Login exitoso",
  "user": {
    "id": 1,
    "email": "farmaceutico@farmacia.com",
    "username": "farmaceutico1",
    "tipo_usuario": "farmaceutico",
    "first_name": "Juan",
    "last_name": "Pérez"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

**⚠️ IMPORTANTE:** Copia el `access` token para usarlo en las siguientes peticiones.

---

### 4. Ver Mi Perfil (Usuario Autenticado)
**GET** `http://127.0.0.1:8002/auth/me/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Respuesta esperada (200):**
```json
{
  "id": 1,
  "email": "farmaceutico@farmacia.com",
  "username": "farmaceutico1",
  "tipo_usuario": "farmaceutico",
  "first_name": "Juan",
  "last_name": "Pérez",
  "telefono": "0991234567",
  "direccion": "Av. Principal 123, Manta"
}
```

---

## 💊 PRODUCTOS

### 5. Listar Todos los Productos
**GET** `http://127.0.0.1:8002/api/productos/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Respuesta esperada (200) - Farmacéutico (ve stock):**
```json
[
  {
    "id_producto": 1,
    "nombre_generico": "Paracetamol",
    "nombre_comercial": "Tylenol",
    "principio_activo": "Paracetamol",
    "categoria": "Analgésicos",
    "presentacion": "Tabletas",
    "concentracion": "500mg",
    "stock": 100,
    "precio": "2.50",
    "created_at": "2026-01-02T12:00:00Z",
    "updated_at": "2026-01-02T12:00:00Z"
  }
]
```

**Respuesta esperada (200) - Cliente (NO ve stock):**
```json
[
  {
    "id_producto": 1,
    "nombre_generico": "Paracetamol",
    "nombre_comercial": "Tylenol",
    "principio_activo": "Paracetamol",
    "categoria": "Analgésicos",
    "presentacion": "Tabletas",
    "concentracion": "500mg",
    "precio": "2.50"
  }
]
```

---

### 6. Crear Producto (Solo Farmacéutico)
**POST** `http://127.0.0.1:8002/api/productos/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "nombre_generico": "Paracetamol",
  "nombre_comercial": "Tylenol",
  "principio_activo": "Paracetamol",
  "categoria": "Analgésicos",
  "presentacion": "Tabletas",
  "concentracion": "500mg",
  "stock": 100,
  "precio": 2.50
}
```

**Más ejemplos de productos:**

```json
{
  "nombre_generico": "Ibuprofeno",
  "nombre_comercial": "Advil",
  "principio_activo": "Ibuprofeno",
  "categoria": "Antiinflamatorios",
  "presentacion": "Cápsulas",
  "concentracion": "400mg",
  "stock": 150,
  "precio": 3.75
}
```

```json
{
  "nombre_generico": "Amoxicilina",
  "nombre_comercial": "Amoxil",
  "principio_activo": "Amoxicilina",
  "categoria": "Antibióticos",
  "presentacion": "Suspensión",
  "concentracion": "250mg/5ml",
  "stock": 50,
  "precio": 8.50
}
```

```json
{
  "nombre_generico": "Omeprazol",
  "nombre_comercial": "Prilosec",
  "principio_activo": "Omeprazol",
  "categoria": "Antiácidos",
  "presentacion": "Cápsulas",
  "concentracion": "20mg",
  "stock": 80,
  "precio": 5.25
}
```

```json
{
  "nombre_generico": "Loratadina",
  "nombre_comercial": "Clarityne",
  "principio_activo": "Loratadina",
  "categoria": "Antihistamínicos",
  "presentacion": "Tabletas",
  "concentracion": "10mg",
  "stock": 120,
  "precio": 4.00
}
```

---

### 7. Ver Detalle de un Producto
**GET** `http://127.0.0.1:8002/api/productos/1/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

---

### 8. Actualizar Producto (Solo Farmacéutico)
**PUT** `http://127.0.0.1:8002/api/productos/1/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json
```

**Body (raw JSON) - Actualización parcial:**
```json
{
  "stock": 80,
  "precio": 2.75
}
```

**Body (raw JSON) - Actualización completa:**
```json
{
  "nombre_generico": "Paracetamol",
  "nombre_comercial": "Tylenol Extra Fuerte",
  "principio_activo": "Paracetamol",
  "categoria": "Analgésicos",
  "presentacion": "Tabletas",
  "concentracion": "750mg",
  "stock": 80,
  "precio": 3.00
}
```

---

### 9. Eliminar Producto (Solo Farmacéutico)
**DELETE** `http://127.0.0.1:8002/api/productos/1/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Respuesta esperada (204):** Sin contenido

---

## 🛒 VENTAS

### 10. Listar Ventas
**GET** `http://127.0.0.1:8002/api/ventas/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Respuesta esperada (200):**
```json
[
  {
    "id_venta": 1,
    "cliente": {
      "id": 2,
      "username": "cliente1",
      "email": "cliente@gmail.com"
    },
    "farmaceutico": {
      "id": 1,
      "username": "farmaceutico1",
      "email": "farmaceutico@farmacia.com"
    },
    "total": "15.50",
    "created_at": "2026-01-02T14:30:00Z"
  }
]
```

**Nota:** 
- **Farmacéuticos** ven todas las ventas
- **Clientes** solo ven sus propias compras

---

### 11. Crear Venta (Solo Farmacéutico)
**POST** `http://127.0.0.1:8002/api/ventas/`

**Headers:**
```
Authorization: Bearer <token_farmaceutico>
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "cliente": 2,
  "detalles": [
    {
      "producto": 1,
      "cantidad": 2
    },
    {
      "producto": 2,
      "cantidad": 1
    }
  ]
}
```

**Explicación:**
- `cliente`: ID del cliente que realiza la compra
- `detalles`: Array de productos con sus cantidades
- El sistema calcula automáticamente:
  - `precio_unitario` (del producto)
  - `subtotal` (precio_unitario × cantidad)
  - `total` (suma de todos los subtotales)
  - Descuenta el stock automáticamente

**Más ejemplos:**

```json
{
  "cliente": 2,
  "detalles": [
    {
      "producto": 1,
      "cantidad": 5
    },
    {
      "producto": 3,
      "cantidad": 2
    },
    {
      "producto": 4,
      "cantidad": 1
    }
  ]
}
```

```json
{
  "cliente": 3,
  "detalles": [
    {
      "producto": 2,
      "cantidad": 10
    }
  ]
}
```

**Respuesta esperada (201):**
```json
{
  "id_venta": 1,
  "cliente": {
    "id": 2,
    "username": "cliente1",
    "email": "cliente@gmail.com",
    "first_name": "María",
    "last_name": "García"
  },
  "farmaceutico": {
    "id": 1,
    "username": "farmaceutico1",
    "email": "farmaceutico@farmacia.com",
    "first_name": "Juan",
    "last_name": "Pérez"
  },
  "detalles": [
    {
      "id_detalle": 1,
      "producto": {
        "id_producto": 1,
        "nombre_comercial": "Tylenol",
        "nombre_generico": "Paracetamol"
      },
      "cantidad": 2,
      "precio_unitario": "2.50",
      "subtotal": "5.00"
    },
    {
      "id_detalle": 2,
      "producto": {
        "id_producto": 2,
        "nombre_comercial": "Advil",
        "nombre_generico": "Ibuprofeno"
      },
      "cantidad": 1,
      "precio_unitario": "3.75",
      "subtotal": "3.75"
    }
  ],
  "total": "8.75",
  "created_at": "2026-01-02T14:30:00Z"
}
```

---

### 12. Ver Detalle de Venta
**GET** `http://127.0.0.1:8002/api/ventas/1/`

**Headers:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Nota:**
- **Farmacéuticos** pueden ver cualquier venta
- **Clientes** solo pueden ver sus propias compras

---

## 📋 FLUJO COMPLETO DE PRUEBA

### Paso 1: Registrar usuarios
1. Registrar un farmacéutico (guarda el token)
2. Registrar un cliente (guarda el token)

### Paso 2: Crear productos (con token de farmacéutico)
1. Crear 5-10 productos con diferentes datos

### Paso 3: Listar productos (con ambos tokens)
1. Listar como farmacéutico (verás el stock)
2. Listar como cliente (NO verás el stock)

### Paso 4: Realizar ventas (con token de farmacéutico)
1. Crear 2-3 ventas para diferentes clientes

### Paso 5: Ver ventas
1. Como farmacéutico: verás todas las ventas
2. Como cliente: solo verás tus propias compras

### Paso 6: Actualizar/Eliminar productos (con token de farmacéutico)
1. Actualizar stock de un producto
2. Eliminar un producto

---

## 🔑 ERRORES COMUNES

### 401 Unauthorized
```json
{
  "detail": "Authentication credentials were not provided."
}
```
**Solución:** Asegúrate de incluir el header `Authorization: Bearer <token>`

### 403 Forbidden
```json
{
  "error": "Solo los farmaceuticos pueden crear productos"
}
```
**Solución:** Usa un token de usuario con el rol correcto

### 400 Bad Request
```json
{
  "email": ["Este campo es requerido."]
}
```
**Solución:** Verifica que todos los campos requeridos estén en el JSON

### 404 Not Found
```json
{
  "detail": "No encontrado."
}
```
**Solución:** Verifica que el ID del recurso exista

---

## 🎯 TIPS PARA POSTMAN

### 1. Crear una Colección
Crea una colección llamada "Farmacia Service" y organiza las peticiones por carpetas:
- 🔐 Autenticación
- 💊 Productos
- 🛒 Ventas

### 2. Variables de Entorno
Crea variables en Postman:
```
base_url = http://127.0.0.1:8002
token_farmaceutico = (copiar después del login)
token_cliente = (copiar después del login)
```

### 3. Usar Variables
En las URLs:
```
{{base_url}}/auth/login/
```

En los Headers:
```
Authorization: Bearer {{token_farmaceutico}}
```

### 4. Tests Automáticos
Agrega este script en la pestaña "Tests" del login:
```javascript
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("token_farmaceutico", jsonData.tokens.access);
}
```

---

## 🎨 COLECCIÓN DE POSTMAN

También puedes importar esta colección JSON en Postman para tener todos los endpoints listos.

**¿Quieres que genere el archivo JSON de la colección de Postman?** 
Solo dime y lo creo para que lo importes directamente.
