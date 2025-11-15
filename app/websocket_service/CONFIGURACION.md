# Configuración del Sistema de Notificaciones WebSocket

## Variables de Entorno

### Servidor WebSocket (.env en websocket_web2/)

```env
# Puerto del servidor WebSocket
PORT=8080

# Modo de desarrollo
NODE_ENV=development

# Logging
LOG_LEVEL=info
```

### Panel Administrativo (app.js)

Configurables desde la interfaz:

```javascript
// URL de la API REST (cambiar según environment)
API_URL: 'https://salumedx-rest.onrender.com'

// URL del Servidor WebSocket (cambiar según environment)
WEBSOCKET_URL: 'http://localhost:8080'

// URL de GraphQL (para futuras migraciones)
GRAPHQL_URL: 'http://localhost:4000/graphql'
```

## Configuración por Ambiente

### Desarrollo

```javascript
// app.js
API_URL: 'http://localhost:3000'
WEBSOCKET_URL: 'http://localhost:8080'
```

### Staging

```javascript
// app.js
API_URL: 'https://staging-api.salumedx.com'
WEBSOCKET_URL: 'https://staging-ws.salumedx.com'
```

### Producción

```javascript
// app.js
API_URL: 'https://api.salumedx.com'
WEBSOCKET_URL: 'https://ws.salumedx.com'
```

## Tipos de Notificaciones

### 1. PRODUCT_CREATED
Se envía cuando se crea un nuevo producto

**Estructura**:
```json
{
  "type": "PRODUCT_CREATED",
  "data": {
    "id": 1,
    "nombre_comercial": "Paracetamol 500mg",
    "nombre_generico": "Acetaminofén",
    "precio": 5.50,
    "mensaje": "Nuevo producto: Paracetamol 500mg"
  },
  "timestamp": "2025-11-14T10:30:45.123Z",
  "user": "admin_username"
}
```

### 2. PHARMACY_CREATED
Se envía cuando se crea una nueva farmacia

**Estructura**:
```json
{
  "type": "PHARMACY_CREATED",
  "data": {
    "id": 1,
    "nombre": "Farmacia Central",
    "direccion": "Calle Principal 123",
    "telefono": "555-1234",
    "mensaje": "Nueva farmacia: Farmacia Central"
  },
  "timestamp": "2025-11-14T10:30:45.123Z",
  "user": "admin_username"
}
```

### 3. PRODUCT_PHARMACY_RELATION_CREATED
Se envía cuando se crea una relación producto-farmacia

**Estructura**:
```json
{
  "type": "PRODUCT_PHARMACY_RELATION_CREATED",
  "data": {
    "id": 1,
    "producto_id": 1,
    "farmacia_id": 1,
    "precio": 5.99,
    "stock": 100,
    "mensaje": "Nueva relación: Producto 1 en Farmacia 1"
  },
  "timestamp": "2025-11-14T10:30:45.123Z",
  "user": "admin_username"
}
```

## Métodos en app.js

### sendWebSocketNotification(type, data)

Método auxiliar que envía notificaciones al servidor WebSocket

**Parámetros**:
- `type` (string): Tipo de notificación (PRODUCT_CREATED, PHARMACY_CREATED, PRODUCT_PHARMACY_RELATION_CREATED)
- `data` (object): Datos de la notificación

**Uso**:
```javascript
await this.sendWebSocketNotification('PRODUCT_CREATED', {
  id: createdProduct.id,
  nombre_comercial: createdProduct.nombre_comercial,
  nombre_generico: createdProduct.nombre_generico,
  precio: createdProduct.precio,
  mensaje: `Nuevo producto: ${createdProduct.nombre_comercial}`
});
```

**Opciones de solicitud**:
- Headers: `Content-Type: application/json`
- Timeout: 5 segundos
- ValidateStatus: Todas las respuestas se aceptan (no falla si hay error)

**Comportamiento**:
- Si es exitosa: Registra en consola `✅ Notificación enviada`
- Si falla: Registra warning `⚠ No se pudo enviar notificación WebSocket`
- No interrumpe el flujo de la operación principal

## Endpoints

### POST /api/notifications

Recibe notificaciones desde el panel administrativo

**Request**:
```http
POST /api/notifications HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "type": "PRODUCT_CREATED",
  "data": {...},
  "timestamp": "2025-11-14T10:30:45.123Z",
  "user": "admin_username"
}
```

**Response**:
```json
{
  "message": "Notificación enviada UWU OKI",
  "type": "PRODUCT_CREATED",
  "broadcastTo": 5
}
```

### WebSocket /

Conexión bidireccional para recibir notificaciones

**Cliente se suscribe**:
```javascript
const socket = new WebSocket('ws://localhost:8080');

socket.onmessage = (event) => {
  const { event: type, data } = JSON.parse(event.data);
  // Procesar notificación
};
```

**Servidor envía**:
```json
{
  "event": "PRODUCT_CREATED",
  "data": {...}
}
```

## Logging

### Servidor WebSocket

Los logs aparecen en la terminal:

```
✅ Servidor escuchando en http://localhost:8080
🟢 Cliente conectado
📨 Recibida notificación: PRODUCT_CREATED
📤 Notificación reenviada a 3 clientes
🔴 Cliente desconectado
```

### Panel Administrativo

Los logs aparecen en la consola del navegador (F12):

```javascript
// Exitosa
✅ Notificación enviada: PRODUCT_CREATED {
  id: 1,
  nombre_comercial: "Paracetamol",
  ...
}

// Error
⚠ No se pudo enviar notificación WebSocket: Network Error
```

### Dashboard

Los logs aparecen en el panel "Registro de Eventos":

```
📌 [10:30:45] Dashboard iniciado
✨ [10:30:46] Conectado al servidor WebSocket
📦 [10:30:50] Evento recibido: PRODUCT_CREATED
✅ [10:30:50] Producto creado exitosamente
```

## CORS y Seguridad

### Configuración Actual

- ✅ Acepta solicitudes de cualquier origen
- ✅ Método POST en `/api/notifications`
- ✅ No requiere autenticación

### Para Producción

Implementar en `server.ts`:

```typescript
import cors from 'cors';

app.use(cors({
  origin: ['https://salumedx.com', 'https://admin.salumedx.com'],
  credentials: true
}));

// Validar JWT en /api/notifications
app.post('/api/notifications', authenticateJWT, (req, res) => {
  // ...
});
```

## Performance

### Límites Recomendados

- **Máximo de clientes conectados**: 1000
- **Máximo de notificaciones por segundo**: 100
- **Tamaño máximo de mensaje**: 10KB

### Optimizaciones Implementadas

- Patrón Singleton para WebSocketServer
- Broadcast eficiente (sin copiar datos)
- Desconexión automática de clientes inactivos
- Compresión de mensajes JSON

## Troubleshooting

### Puerto ya está en uso

```bash
# Linux/Mac
lsof -i :8080
kill -9 <PID>

# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

### WebSocket no conecta

1. Verifica firewall
2. Verifica CORS
3. Verifica URL en app.js
4. Verifica console.log en DevTools

### Notificaciones lentas

1. Verifica conexión de red
2. Monitorea CPU del servidor
3. Revisa cantidad de clientes conectados
4. Aumenta timeout si es necesario

## Testing

### Probar manualmente

```bash
# Enviar notificación de prueba
curl -X POST http://localhost:8080/api/notifications \
  -H "Content-Type: application/json" \
  -d '{
    "type": "PRODUCT_CREATED",
    "data": {"id": 1, "nombre_comercial": "Test"},
    "timestamp": "2025-11-14T10:30:45Z",
    "user": "test"
  }'
```

### Monitorear WebSocket

```javascript
// En la consola del navegador
const ws = new WebSocket('ws://localhost:8080');
ws.onmessage = e => console.log(JSON.parse(e.data));
```

---

**Versión**: 1.0.0
**Última actualización**: 14 de Noviembre, 2025
