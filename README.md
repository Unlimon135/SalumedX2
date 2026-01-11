# Farmacia Service

Microservicio backend para gestión de farmacia individual con inventario y ventas.

## 🏗️ Arquitectura

Este microservicio forma parte de la arquitectura de microservicios SalumedX:
- **Puerto:** 8002
- **Auth Service:** Puerto 8001
- **SalumedX REST:** Puerto 8000

## 📋 Características

### Usuarios
- **Farmacéutico:** Gestión completa de inventario y ventas
- **Cliente:** Visualización de productos y historial de compras

### Funcionalidades

**Farmacéutico:**
- ✅ Ver stock completo de productos
- ✅ Crear, editar y eliminar productos
- ✅ Registrar ventas a clientes
- ✅ Ver historial completo de ventas

**Cliente:**
- ✅ Ver catálogo de productos (sin stock visible)
- ✅ Ver historial de sus propias compras

## 🔧 Instalación y Ejecución

### ⚠️ Nota Importante sobre Python
Este proyecto requiere **Python 3.10** ya que las dependencias están instaladas en esa versión.
Si tienes múltiples versiones de Python, usa la ruta completa:
```
C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe
```

### Opción 1: Usando Scripts PowerShell (Recomendado - Windows)

#### 1. Ejecutar migraciones
```powershell
.\migrate.ps1
```

#### 2. Crear superusuario (opcional, para acceder al admin)
```powershell
.\create_superuser.ps1
```

#### 3. Iniciar servidor
```powershell
.\run.ps1
```

### Opción 2: Comandos Manuales

#### 1. Configurar variables de entorno (ya creado)
El archivo `.env` ya está configurado. Si necesitas modificarlo:
```bash
# El archivo .env contiene:
# SECRET_KEY=django-insecure-farmacia-dev-key-123456789
# DEBUG=True
# PORT=8002
```

#### 2. Ejecutar migraciones
```bash
C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe manage.py makemigrations
C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe manage.py migrate
```

#### 3. Crear superusuario (opcional)
```bash
C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe manage.py createsuperuser
```

#### 4. Iniciar servidor
```bash
C:\Users\LENOVO\AppData\Local\Programs\Python\Python310\python.exe manage.py runserver 8002
```

### ✅ El servidor estará disponible en: http://127.0.0.1:8002/

### 🗄️ Base de Datos
El proyecto usa **SQLite** (`db.sqlite3`), que se crea automáticamente al ejecutar las migraciones.

## 📡 Endpoints API

### Autenticación

#### Registro
```http
POST /auth/register/
Content-Type: application/json

{
  "email": "farmaceutico@farmacia.com",
  "username": "farmaceutico1",
  "password": "MiPassword123!",
  "password2": "MiPassword123!",
  "tipo_usuario": "farmaceutico",
  "first_name": "Juan",
  "last_name": "Pérez",
  "telefono": "0991234567",
  "direccion": "Av. Principal 123"
}
```

#### Login
```http
POST /auth/login/
Content-Type: application/json

{
  "email": "farmaceutico@farmacia.com",
  "password": "MiPassword123!"
}
```

#### Ver perfil
```http
GET /auth/me/
Authorization: Bearer {access_token}
```

### Productos

#### Listar productos
```http
GET /api/productos/
Authorization: Bearer {access_token}

# Respuesta para farmacéutico (con stock):
[
  {
    "id_producto": 1,
    "nombre_generico": "Paracetamol",
    "nombre_comercial": "Panadol",
    "principio_activo": "Paracetamol",
    "categoria": "Analgésico",
    "presentacion": "Tabletas",
    "concentracion": "500mg",
    "stock": 100,
    "precio": "5.50",
    "created_at": "2026-01-02T10:00:00Z",
    "updated_at": "2026-01-02T10:00:00Z"
  }
]

# Respuesta para cliente (sin stock):
[
  {
    "id_producto": 1,
    "nombre_generico": "Paracetamol",
    "nombre_comercial": "Panadol",
    "principio_activo": "Paracetamol",
    "categoria": "Analgésico",
    "presentacion": "Tabletas",
    "concentracion": "500mg",
    "precio": "5.50"
  }
]
```

#### Crear producto (solo farmacéutico)
```http
POST /api/productos/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "nombre_generico": "Ibuprofeno",
  "nombre_comercial": "Advil",
  "principio_activo": "Ibuprofeno",
  "categoria": "Antiinflamatorio",
  "presentacion": "Tabletas",
  "concentracion": "400mg",
  "stock": 50,
  "precio": "8.75"
}
```

#### Ver/Actualizar/Eliminar producto
```http
GET /api/productos/{id}/
PUT /api/productos/{id}/
DELETE /api/productos/{id}/
Authorization: Bearer {access_token}
```

### Ventas

#### Listar ventas
```http
GET /api/ventas/
Authorization: Bearer {access_token}

# Farmacéutico ve todas las ventas
# Cliente solo ve sus propias compras
```

#### Crear venta (solo farmacéutico)
```http
POST /api/ventas/
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "cliente": 2,
  "detalles": [
    {
      "producto": 1,
      "cantidad": 2
    },
    {
      "producto": 3,
      "cantidad": 1
    }
  ]
}

# Respuesta:
{
  "id_venta": 1,
  "cliente": 2,
  "cliente_nombre": "maria_cliente",
  "farmaceutico": 1,
  "farmaceutico_nombre": "juan_farmaceutico",
  "total": "19.00",
  "detalles": [
    {
      "id_detalle": 1,
      "producto": 1,
      "producto_nombre": "Panadol",
      "cantidad": 2,
      "precio_unitario": "5.50",
      "subtotal": "11.00"
    },
    {
      "id_detalle": 2,
      "producto": 3,
      "producto_nombre": "Advil",
      "cantidad": 1,
      "precio_unitario": "8.00",
      "subtotal": "8.00"
    }
  ],
  "created_at": "2026-01-02T14:30:00Z"
}
```

#### Ver detalle de venta
```http
GET /api/ventas/{id}/
Authorization: Bearer {access_token}
```

## 📊 Modelos de Datos

### User
- `id`: AutoField
- `email`: EmailField (unique)
- `username`: CharField (unique)
- `tipo_usuario`: 'farmaceutico' | 'cliente'
- `first_name`, `last_name`, `telefono`, `direccion`

### Producto
- `id_producto`: AutoField
- `nombre_generico`, `nombre_comercial`, `principio_activo`
- `categoria`, `presentacion`, `concentracion`
- `stock`: IntegerField
- `precio`: DecimalField

### Venta
- `id_venta`: AutoField
- `cliente`: FK(User)
- `farmaceutico`: FK(User)
- `total`: DecimalField

### DetalleVenta
- `id_detalle`: AutoField
- `venta`: FK(Venta)
- `producto`: FK(Producto)
- `cantidad`, `precio_unitario`, `subtotal`

## 🔐 Autenticación

JWT con Bearer Token:
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🚀 Próxima Integración con SalumedX

Este microservicio se integrará con SalumedX REST API para:
1. Registrar la farmacia en SalumedX
2. Sincronizar inventario (sin stock)
3. Recibir órdenes de compra desde SalumedX

## 💳 Pilar 2 - Stripe Payment Service

Servicio Express + TypeScript separado para pagos con Stripe (modo test) usando patrón Adapter y webhook hacia Django.

### Variables de entorno necesarias
- STRIPE_SECRET_KEY=sk_test_xxx
- STRIPE_WEBHOOK_SECRET=whsec_xxx
- INTERNAL_SECRET=token-interno-compartido (mismo valor en Django y payment_service)
- DJANGO_CONFIRM_URL=http://localhost:8000/api/pagos/confirmar/ (opcional si se usa otro host)
- PORT=4000 (opcional para payment_service)

### Puesta en marcha del payment_service
1. `cd payment_service`
2. `npm install`
3. Copiar `.env.example` a `.env` y completar valores de Stripe e INTERNAL_SECRET.
4. `npm run dev` para correr en modo desarrollo (default puerto 4000).
5. Configurar en Stripe CLI o Dashboard el webhook apuntando a `http://localhost:4000/webhooks/stripe`.

### Flujo
- `POST /pay` crea un PaymentIntent (StripeAdapter) y devuelve `clientSecret` + `paymentIntentId`.
- Stripe envía `payment_intent.succeeded` al webhook -> se valida firma -> se notifica a Django en `/api/pagos/confirmar/` con header `X-INTERNAL-SECRET`.

## 🛠️ Stack Tecnológico

- Django 5.2.7
- Django REST Framework 3.15.2
- djangorestframework-simplejwt 5.3.1
- SQLite (desarrollo) / PostgreSQL (producción)
- JWT Authentication

## 📝 Notas de Desarrollo

- El stock solo es visible para farmacéuticos
- Las ventas actualizan automáticamente el stock
- Los clientes solo ven sus propias compras
- Los farmacéuticos tienen acceso completo
