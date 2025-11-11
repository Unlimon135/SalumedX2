# 📊 Sistema de Consultas de Productos

## ✅ Implementación Completada

Se creó el modelo `ConsultaProducto` para registrar búsquedas de usuarios (con o sin receta) de forma separada de las prescripciones médicas.

---

## 🎯 **Problema Resuelto**

**Antes:** No había forma de registrar cuando usuarios consultan precios sin tener una receta.

**Ahora:** Sistema separado que permite:
- ✅ Registrar búsquedas de usuarios anónimos
- ✅ Registrar búsquedas de usuarios autenticados
- ✅ Historial de consultas por usuario
- ✅ Analítica de productos más consultados
- ✅ No mezcla conceptos con `DetallePrescripcion`

---

## 📊 **Nuevo Modelo: ConsultaProducto**

```python
class ConsultaProducto:
    id_consulta (PK)
    user (FK User, nullable) → Usuario que consultó (null si anónimo)
    producto (FK Producto) → Producto consultado
    farmacia (FK Farmacia, nullable) → Farmacia específica consultada
    producto_farmacia (FK ProductoFarmacia, nullable) → Precio oficial consultado
    precio_visto (Decimal) → Precio que vio el usuario
    origen (String) → 'public_search', 'user_interest', 'saved', 'comparison'
    created_at (DateTime) → Fecha/hora de la consulta
```

**Características:**
- Índices en `(user, created_at)` y `(producto, created_at)` para consultas rápidas
- Ordenamiento por defecto: más recientes primero
- Soporte para usuarios anónimos (user=None)

---

## 🌐 **Nuevos Endpoints**

### **1. POST `/consultas-producto/` - Registrar Consulta**

**Autenticación:** No requerida (AllowAny)

**Uso:** Cuando un usuario (anónimo o registrado) consulta el precio de un producto.

**Request Body:**
```json
{
  "producto_id": 5,
  "farmacia_id": 2,              // opcional
  "producto_farmacia_id": 10,    // opcional
  "precio_visto": "3.50",
  "origen": "public_search"      // public_search, user_interest, saved, comparison
}
```

**Ejemplo con cURL:**
```bash
# Usuario anónimo consultando precio
curl -X POST https://salumedx-rest.onrender.com/consultas-producto/ \
  -H "Content-Type: application/json" \
  -d '{
    "producto_id": 5,
    "farmacia_id": 2,
    "precio_visto": "3.50",
    "origen": "public_search"
  }'

# Usuario autenticado guardando un favorito
curl -X POST https://salumedx-rest.onrender.com/consultas-producto/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "producto_id": 5,
    "farmacia_id": 2,
    "producto_farmacia_id": 10,
    "precio_visto": "3.50",
    "origen": "saved"
  }'
```

**Response (201 Created):**
```json
{
  "success": true,
  "consulta": {
    "id_consulta": 1,
    "user": {
      "id": 5,
      "username": "juan123"
    },
    "producto": {
      "id_producto": 5,
      "nombre_comercial": "Ibuprofeno 400mg",
      "precio_base": "3.00"
    },
    "farmacia": {
      "id_farmacia": 2,
      "nombre_comercial": "Farmacia Cruz Azul"
    },
    "precio_visto": "3.50",
    "origen": "public_search",
    "created_at": "2025-11-11T15:30:00Z"
  },
  "mensaje": "Consulta registrada exitosamente"
}
```

**Tipos de origen:**
- `public_search` - Búsqueda pública general
- `user_interest` - Usuario mostró interés en el producto
- `saved` - Usuario guardó como favorito
- `comparison` - Comparación de precios entre farmacias

---

### **2. GET `/mis-consultas/` - Historial del Usuario**

**Autenticación:** Requerida (IsAuthenticated)

**Uso:** Ver historial de consultas del usuario autenticado.

**Query Params (todos opcionales):**
- `?producto=<id>` - Filtrar por producto específico
- `?farmacia=<id>` - Filtrar por farmacia específica
- `?origen=<tipo>` - Filtrar por tipo de origen
- `?limit=<n>` - Limitar resultados (default: 50)

**Ejemplos:**
```bash
# Todas las consultas del usuario
curl https://salumedx-rest.onrender.com/mis-consultas/ \
  -H "Authorization: Bearer <token>"

# Consultas de un producto específico
curl https://salumedx-rest.onrender.com/mis-consultas/?producto=5 \
  -H "Authorization: Bearer <token>"

# Solo favoritos guardados
curl https://salumedx-rest.onrender.com/mis-consultas/?origen=saved \
  -H "Authorization: Bearer <token>"

# Últimas 10 consultas
curl https://salumedx-rest.onrender.com/mis-consultas/?limit=10 \
  -H "Authorization: Bearer <token>"
```

**Response (200 OK):**
```json
{
  "success": true,
  "consultas": [
    {
      "id_consulta": 15,
      "producto": {
        "id_producto": 5,
        "nombre_comercial": "Ibuprofeno 400mg",
        "nombre_generico": "Ibuprofeno"
      },
      "farmacia": {
        "id_farmacia": 2,
        "nombre_comercial": "Farmacia Cruz Azul"
      },
      "precio_visto": "3.50",
      "origen": "saved",
      "created_at": "2025-11-11T15:30:00Z"
    }
  ],
  "total": 1
}
```

---

### **3. GET `/estadisticas-consultas/` - Estadísticas Públicas**

**Autenticación:** No requerida (AllowAny)

**Uso:** Ver productos y farmacias más consultados.

**Ejemplo:**
```bash
curl https://salumedx-rest.onrender.com/estadisticas-consultas/
```

**Response (200 OK):**
```json
{
  "success": true,
  "estadisticas": {
    "total_consultas": 1523,
    "productos_mas_consultados": [
      {
        "producto__id_producto": 5,
        "producto__nombre_comercial": "Ibuprofeno 400mg",
        "producto__nombre_generico": "Ibuprofeno",
        "total_consultas": 245
      },
      {
        "producto__id_producto": 12,
        "producto__nombre_comercial": "Paracetamol 500mg",
        "producto__nombre_generico": "Paracetamol",
        "total_consultas": 198
      }
    ],
    "farmacias_mas_consultadas": [
      {
        "farmacia__id_farmacia": 2,
        "farmacia__nombre_comercial": "Farmacia Cruz Azul",
        "total_consultas": 312
      },
      {
        "farmacia__id_farmacia": 1,
        "farmacia__nombre_comercial": "Farmacia Económica",
        "total_consultas": 287
      }
    ]
  }
}
```

---

## 🔄 **Flujos de Uso**

### **Flujo 1: Usuario Anónimo Consulta Precios**

```javascript
// Frontend Vue/React
async function buscarPreciosProducto(productoId) {
  // 1. Mostrar precios al usuario (endpoint público)
  const response = await fetch(
    `https://salumedx-rest.onrender.com/comparar-precios/?producto=${productoId}`
  );
  const data = await response.json();
  
  // Mostrar precios en UI
  mostrarPrecios(data.precios_por_farmacia);
  
  // 2. Registrar la consulta (sin token)
  await fetch('https://salumedx-rest.onrender.com/consultas-producto/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      producto_id: productoId,
      precio_visto: data.estadisticas.precio_minimo,
      origen: 'public_search'
    })
  });
}
```

---

### **Flujo 2: Usuario Registrado Guarda Favorito**

```javascript
// Frontend con usuario autenticado
async function guardarFavorito(productoId, farmaciaId, precio) {
  const token = localStorage.getItem('access_token');
  
  const response = await fetch('https://salumedx-rest.onrender.com/consultas-producto/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      producto_id: productoId,
      farmacia_id: farmaciaId,
      precio_visto: precio,
      origen: 'saved'  // ← Marcado como favorito
    })
  });
  
  if (response.ok) {
    alert('Producto guardado en favoritos');
  }
}
```

---

### **Flujo 3: Usuario Ve su Historial**

```javascript
// Frontend - Ver historial de consultas
async function verHistorial() {
  const token = localStorage.getItem('access_token');
  
  const response = await fetch('https://salumedx-rest.onrender.com/mis-consultas/', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  const data = await response.json();
  mostrarHistorial(data.consultas);
}

// Filtrar solo favoritos
async function verFavoritos() {
  const token = localStorage.getItem('access_token');
  
  const response = await fetch(
    'https://salumedx-rest.onrender.com/mis-consultas/?origen=saved',
    {
      headers: { 'Authorization': `Bearer ${token}` }
    }
  );
  
  const data = await response.json();
  mostrarFavoritos(data.consultas);
}
```

---

## 🎨 **Integración con GraphQL (Sinatra)**

```ruby
# En tu schema de GraphQL

# Type para ConsultaProducto
ConsultaProductoType = GraphQL::ObjectType.define do
  name 'ConsultaProducto'
  
  field :id, !types.Int
  field :producto, ProductoType
  field :farmacia, FarmaciaType
  field :precio_visto, !types.Float
  field :origen, !types.String
  field :created_at, !types.String
end

# Query para obtener historial
field :misConsultas, types[ConsultaProductoType] do
  argument :origen, types.String
  argument :limit, types.Int
  
  resolve ->(obj, args, ctx) {
    token = ctx[:current_user_token]
    url = URI("https://salumedx-rest.onrender.com/mis-consultas/")
    
    params = {}
    params[:origen] = args[:origen] if args[:origen]
    params[:limit] = args[:limit] if args[:limit]
    url.query = URI.encode_www_form(params) if params.any?
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{token}"
    
    response = http.request(request)
    result = JSON.parse(response.body)
    result['consultas']
  }
end

# Mutation para registrar consulta
field :registrarConsulta, ConsultaProductoType do
  argument :producto_id, !types.Int
  argument :farmacia_id, types.Int
  argument :precio_visto, !types.Float
  argument :origen, !types.String
  
  resolve ->(obj, args, ctx) {
    token = ctx[:current_user_token]
    url = URI("https://salumedx-rest.onrender.com/consultas-producto/")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{token}" if token
    request.body = {
      producto_id: args[:producto_id],
      farmacia_id: args[:farmacia_id],
      precio_visto: args[:precio_visto],
      origen: args[:origen]
    }.to_json
    
    response = http.request(request)
    result = JSON.parse(response.body)
    result['consulta']
  }
end
```

---

## 🔐 **Panel de Admin**

El admin puede ver todas las consultas con:
- Filtros por: origen, fecha, farmacia, categoría de producto
- Búsqueda por: usuario, producto, farmacia
- Ordenamiento por fecha (más recientes primero)
- Jerarquía de fechas para navegación temporal

**Acceso:**
```
https://salumedx-rest.onrender.com/admin/login/consultaproducto/
```

---

## 📊 **Comparación: DetallePrescripcion vs ConsultaProducto**

| Característica | DetallePrescripcion | ConsultaProducto |
|----------------|---------------------|------------------|
| **Propósito** | Registrar precios encontrados para una receta específica | Registrar búsquedas/consultas generales |
| **Requiere Receta** | ✅ Sí (FK obligatorio) | ❌ No |
| **Usuario Anónimo** | ❌ No permitido | ✅ Permitido |
| **Vinculado a** | DetalleReceta | Producto + Farmacia (opcional) |
| **Usado por** | Pacientes con recetas | Cualquier usuario |
| **Caso de uso** | "¿Dónde compro mis medicamentos recetados?" | "¿Cuánto cuesta este producto?" |

---

## ✅ **Archivos Modificados/Creados**

1. ✅ `login/models.py` - Agregado modelo `ConsultaProducto`
2. ✅ `login/serializers.py` - Agregado `ConsultaProductoSerializer`
3. ✅ `login/views/consulta_producto_view.py` - **NUEVO** con 3 endpoints
4. ✅ `salumedx_rest/urls.py` - Agregadas 3 rutas nuevas
5. ✅ `login/admin.py` - Configurado admin para `ConsultaProducto`
6. ✅ Migración `0006_consultaproducto.py` aplicada

---

## 🚀 **Deploy**

**Comandos ejecutados localmente:**
```bash
python manage.py makemigrations  # ✅ Migración 0006 creada
python manage.py migrate         # ✅ Tabla creada en BD local
```

**Para deploy en Render:**
```bash
git add .
git commit -m "feat: sistema de consultas de productos sin receta"
git push
```

Render aplicará automáticamente la migración `0006_consultaproducto.py`.

---

## 📝 **Resumen de Endpoints Totales**

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/productos/` | GET | No | Productos con precio base |
| `/farmacias/` | GET | No | Lista de farmacias |
| `/productos-farmacias/` | GET | No | Precios por farmacia |
| `/comparar-precios/` | GET | No | Comparar precios de 1 producto |
| **`/consultas-producto/`** | **POST** | **No** | **Registrar consulta** |
| **`/mis-consultas/`** | **GET** | **Sí** | **Historial usuario** |
| **`/estadisticas-consultas/`** | **GET** | **No** | **Estadísticas públicas** |
| `/recetas/` | GET/POST | Sí | Recetas del usuario |

**Total: 17 endpoints (3 nuevos)** 🎉
