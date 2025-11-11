# 📋 Cambios en el Sistema de Precios

## 🎯 Problema Resuelto

**Antes:** Los precios estaban en `DetallePrescripcion`, lo que significaba:
- ❌ Los usuarios no podían ver precios sin tener una receta
- ❌ Los médicos podían manipular precios al crear recetas
- ❌ No había un catálogo público de precios por farmacia

**Ahora:** Sistema de precios mejorado con:
- ✅ Precios base en cada producto (referencia)
- ✅ Precios específicos por farmacia (gestionados solo por admin)
- ✅ Catálogo público de precios accesible sin autenticación
- ✅ Médicos NO pueden manipular precios

---

## 📊 Nuevos Modelos

### 1. **Producto** (Modificado)
```python
class Producto:
    # ... campos existentes ...
    precio_base = DecimalField()  # ⬅️ NUEVO: Precio de referencia
```

### 2. **ProductoFarmacia** (Nuevo)
```python
class ProductoFarmacia:
    producto = ForeignKey(Producto)
    farmacia = ForeignKey(Farmacia)
    precio = DecimalField()               # Precio específico en esta farmacia
    stock_disponible = PositiveIntegerField()
    fecha_actualizacion = DateTimeField()
```
- **Gestión:** Solo el admin puede crear/modificar
- **Restricción:** Un producto solo puede tener un precio por farmacia (`unique_together`)

### 3. **DetallePrescripcion** (Modificado)
```python
class DetallePrescripcion:
    # ... campos existentes ...
    producto_farmacia = ForeignKey(ProductoFarmacia, null=True)  # ⬅️ NUEVO
    # El campo precio_encontrado se mantiene para compatibilidad con fuentes externas
```

---

## 🌐 Nuevos Endpoints Públicos

### **1. `/productos-farmacias/` - Listar precios**
Retorna precios de productos en farmacias con filtros opcionales.

**GET sin filtros:**
```http
GET https://salumedx-rest.onrender.com/productos-farmacias/
```
```json
{
  "success": true,
  "resultados": [
    {
      "id_producto_farmacia": 1,
      "precio": "5.50",
      "stock_disponible": 100,
      "fecha_actualizacion": "2025-11-11T10:00:00Z",
      "producto": {
        "id_producto": 1,
        "nombre_comercial": "Paracetamol 500mg",
        "precio_base": "4.00"
      },
      "farmacia": {
        "id_farmacia": 1,
        "nombre_comercial": "Farmacia Cruz Azul"
      }
    }
  ],
  "total": 1
}
```

**Filtros disponibles:**
- `?producto=5` - Filtra por ID de producto
- `?farmacia=2` - Filtra por ID de farmacia
- `?nombre=paracetamol` - Busca por nombre del producto
- `?orden=precio` - Ordena por precio ascendente (default)
- `?orden=precio_desc` - Ordena por precio descendente

**Ejemplos:**
```http
# Ver precios de un producto específico en todas las farmacias
GET /productos-farmacias/?producto=5

# Ver todos los productos de una farmacia
GET /productos-farmacias/?farmacia=2

# Buscar producto por nombre
GET /productos-farmacias/?nombre=paracetamol

# Combinación de filtros
GET /productos-farmacias/?producto=5&orden=precio
```

---

### **2. `/comparar-precios/` - Comparar precios de un producto**
Compara precios de un producto específico en todas las farmacias disponibles.

**Requerido:** `?producto=<id>`

```http
GET https://salumedx-rest.onrender.com/comparar-precios/?producto=5
```

**Respuesta:**
```json
{
  "producto": {
    "id": 5,
    "nombre_comercial": "Ibuprofeno 400mg",
    "nombre_generico": "Ibuprofeno",
    "precio_base": "3.50",
    "presentacion": "Tabletas",
    "concentracion": "400mg"
  },
  "estadisticas": {
    "precio_minimo": 3.20,
    "precio_maximo": 5.80,
    "precio_promedio": 4.35,
    "diferencia": 2.60,
    "ahorro_porcentual": 44.83
  },
  "precios_por_farmacia": [
    {
      "id_producto_farmacia": 10,
      "precio": "3.20",
      "stock_disponible": 50,
      "farmacia": {
        "id_farmacia": 3,
        "nombre_comercial": "Farmacia Económica"
      }
    },
    {
      "id_producto_farmacia": 11,
      "precio": "5.80",
      "stock_disponible": 30,
      "farmacia": {
        "id_farmacia": 1,
        "nombre_comercial": "Farmacia Premium"
      }
    }
  ],
  "total_farmacias": 2
}
```

**Características:**
- ✅ Ordena de menor a mayor precio
- ✅ Muestra estadísticas (min, max, promedio)
- ✅ Calcula ahorro porcentual
- ✅ Incluye información completa del producto
- ✅ No requiere autenticación

---

## 🔐 Gestión de Precios (Solo Admin)

### **Acceso al Admin de Django**
```
URL: https://salumedx-rest.onrender.com/admin/
```

### **Agregar Precio de Producto por Farmacia:**
1. Ingresar al admin
2. Ir a "Precios de Productos por Farmacia"
3. Hacer clic en "Agregar"
4. Seleccionar:
   - **Producto:** Producto existente
   - **Farmacia:** Farmacia existente
   - **Precio:** Precio en esta farmacia
   - **Stock disponible:** Cantidad en inventario
5. Guardar

**Validación automática:** No se puede crear dos veces el mismo producto en la misma farmacia.

---

## 📝 Flujos de Uso

### **Flujo 1: Usuario Normal - Ver Precios (Sin Receta)**
```
1. Frontend llama: GET /productos/
   → Obtiene lista de productos con precio_base

2. Frontend llama: GET /comparar-precios/?producto=5
   → Obtiene precios en todas las farmacias

3. Usuario compara y decide dónde comprar
```

### **Flujo 2: Paciente - Ver Precios de su Receta**
```
1. Paciente obtiene receta del médico
2. Frontend llama: GET /recetas/?id=123 (con JWT)
   → Obtiene lista de medicamentos recetados

3. Para cada medicamento:
   Frontend llama: GET /comparar-precios/?producto=<id>
   → Muestra dónde es más barato

4. (Futuro) Frontend puede llamar: POST /detalle-prescripcion/
   → Registra dónde encontró/compró el medicamento
```

### **Flujo 3: Admin - Actualizar Precios**
```
1. Admin ingresa al panel de Django
2. Va a "Precios de Productos por Farmacia"
3. Edita el precio del producto en la farmacia específica
4. Guarda → fecha_actualizacion se actualiza automáticamente
```

---

## 🚀 Próximos Pasos para Deploy

### **1. Actualizar requirements.txt** (Ya hecho)
```txt
dj-database-url
```

### **2. Hacer commit y push**
```bash
git add .
git commit -m "feat: sistema de precios por farmacia + endpoints públicos de comparación"
git push
```

### **3. Render aplicará las migraciones automáticamente**

### **4. Crear datos iniciales en producción**
Después del deploy, ingresar al admin de producción y:
1. Crear farmacias
2. Crear productos con precio_base
3. Definir precios específicos en ProductoFarmacia

---

## 📖 Documentación para el Frontend

### **Endpoints Públicos (No requieren JWT):**
- `GET /productos/` - Lista de productos con precio base
- `GET /farmacias/` - Lista de farmacias
- `GET /sucursales/` - Sucursales con ubicación
- `GET /productos-farmacias/` - Precios por farmacia (con filtros)
- `GET /comparar-precios/?producto=<id>` - Comparar precios

### **Endpoints Protegidos (Requieren JWT):**
- `GET /recetas/` - Recetas del usuario autenticado
- `POST /recetas/` - Crear receta (solo médicos)
- `GET /detalle-prescripcion/` - Búsquedas de precios guardadas

---

## ✅ Ventajas del Nuevo Sistema

1. **Transparencia:** Usuarios ven precios sin necesidad de autenticarse
2. **Comparación:** Fácil comparar precios entre farmacias
3. **Seguridad:** Solo admin puede modificar precios
4. **Escalabilidad:** Fácil agregar nuevas farmacias y productos
5. **Trazabilidad:** Fecha de última actualización de cada precio
6. **Control de inventario:** Campo stock_disponible
7. **Flexibilidad:** DetallePrescripcion puede usar ProductoFarmacia o precio manual

---

## 🎨 Ejemplo de Uso en GraphQL (Sinatra)

```ruby
# Resolver para comparar precios
field :compararPrecios, CompararPreciosType do
  argument :productoId, !types.Int
  
  resolve ->(obj, args, ctx) {
    url = URI("https://salumedx-rest.onrender.com/comparar-precios/")
    url.query = "producto=#{args[:productoId]}"
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(url)
    response = http.request(request)
    
    JSON.parse(response.body)
  }
end
```

---

## 📌 Resumen de Cambios en la Base de Datos

| Tabla | Cambio | Descripción |
|-------|--------|-------------|
| `Producto` | ➕ Campo | `precio_base` (precio de referencia) |
| `ProductoFarmacia` | ➕ Tabla nueva | Precios específicos por farmacia |
| `DetallePrescripcion` | ➕ Campo | `producto_farmacia` (referencia opcional) |
| `DetallePrescripcion` | ℹ️ Campo | `precio_encontrado` se mantiene para compatibilidad |

**Migración aplicada:** `0004_alter_detalleprescripcion_options_and_more.py`
