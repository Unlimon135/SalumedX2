# 🚀 Quick Start - Postman Testing

## 📥 Importar Colección en Postman

1. Abre Postman
2. Click en **Import**
3. Selecciona el archivo: `Farmacia_Service_Postman_Collection.json`
4. ¡Listo! Tendrás todos los endpoints organizados

## 🎯 Prueba Rápida en 5 Minutos

### 1️⃣ Asegúrate de que el servidor esté corriendo
```powershell
.\run.ps1
```
**URL:** http://127.0.0.1:8002

---

### 2️⃣ Registrar Farmacéutico
**POST** `http://127.0.0.1:8002/auth/register/`

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
  "direccion": "Av. Principal 123"
}
```

**⚠️ IMPORTANTE:** Copia el `access` token de la respuesta.

---

### 3️⃣ Registrar Cliente
**POST** `http://127.0.0.1:8002/auth/register/`

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
  "direccion": "Calle 10 de Agosto"
}
```

**⚠️ Guarda el ID del cliente** (ejemplo: `"id": 2`)

---

### 4️⃣ Crear 3 Productos (con token de farmacéutico)
**POST** `http://127.0.0.1:8002/api/productos/`

**Headers:**
```
Authorization: Bearer TU_TOKEN_AQUI
Content-Type: application/json
```

**Producto 1:**
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

**Producto 2:**
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

**Producto 3:**
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

---

### 5️⃣ Listar Productos
**GET** `http://127.0.0.1:8002/api/productos/`

**Headers:**
```
Authorization: Bearer TU_TOKEN_AQUI
```

**Resultado esperado:**
- Como **farmacéutico**: verás el stock
- Como **cliente**: NO verás el stock

---

### 6️⃣ Crear una Venta (con token de farmacéutico)
**POST** `http://127.0.0.1:8002/api/ventas/`

**Headers:**
```
Authorization: Bearer TOKEN_FARMACEUTICO
Content-Type: application/json
```

**Body:**
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

**Nota:** Cambia `"cliente": 2` por el ID que guardaste en el paso 3.

---

### 7️⃣ Ver Ventas
**GET** `http://127.0.0.1:8002/api/ventas/`

**Headers:**
```
Authorization: Bearer TU_TOKEN_AQUI
```

**Resultado:**
- **Farmacéutico**: ve TODAS las ventas
- **Cliente**: solo ve SUS compras

---

## 📋 Checklist de Pruebas

- [ ] ✅ Servidor corriendo en puerto 8002
- [ ] ✅ Registrar farmacéutico (guardar token)
- [ ] ✅ Registrar cliente (guardar token y ID)
- [ ] ✅ Crear 3-5 productos
- [ ] ✅ Listar productos como farmacéutico (ver stock)
- [ ] ✅ Listar productos como cliente (NO ver stock)
- [ ] ✅ Crear 2-3 ventas
- [ ] ✅ Ver ventas como farmacéutico (todas)
- [ ] ✅ Ver ventas como cliente (solo las propias)
- [ ] ✅ Actualizar un producto
- [ ] ✅ Ver perfil de usuario (`/auth/me/`)

---

## 🔑 Tip Pro - Variables en Postman

Crea un **Environment** en Postman con estas variables:

| Variable | Valor |
|----------|-------|
| `base_url` | `http://127.0.0.1:8002` |
| `token_farmaceutico` | (copiar del login) |
| `token_cliente` | (copiar del login) |
| `id_cliente` | (copiar del registro) |

Luego usa en las URLs:
```
{{base_url}}/auth/login/
```

Y en los headers:
```
Authorization: Bearer {{token_farmaceutico}}
```

---

## 📚 Documentación Completa

- **POSTMAN_GUIDE.md** - Guía detallada con todos los endpoints
- **Farmacia_Service_Postman_Collection.json** - Colección para importar

---

## ❓ ¿Problemas?

### Error 401 Unauthorized
❌ No incluiste el token
✅ Agrega: `Authorization: Bearer TU_TOKEN`

### Error 403 Forbidden
❌ Intentas crear productos con token de cliente
✅ Usa el token del farmacéutico

### Error 404
❌ El ID no existe
✅ Verifica el ID del recurso

### Error 400
❌ Faltan campos requeridos
✅ Revisa el JSON del body

---

## 🎉 ¡Listo para probar!

Abre Postman e importa la colección `Farmacia_Service_Postman_Collection.json`
