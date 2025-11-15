# Sistema de Notificaciones en Tiempo Real - SaluMedX

## 📋 Descripción General

Se ha implementado un sistema de notificaciones en tiempo real que permite que cuando se cree un **Producto**, **Farmacia** o **Relación Producto-Farmacia** desde el panel administrativo, se envíe automáticamente una notificación al dashboard en tiempo real a través de WebSocket.

**🔒 El dashboard está protegido por autenticación** - Solo administradores autorizados pueden acceder.

## 🔧 Arquitectura

### Componentes

1. **Panel Administrativo** (`app.html` + `app.js`)
   - Interfaz donde los administradores crean productos, farmacias y relaciones
   - Al guardar, envía notificaciones HTTP POST al servidor WebSocket

2. **Servidor WebSocket** (`websocket_web2/src/server.ts`)
   - Escucha en puerto 8080
   - Recibe notificaciones por HTTP POST en `/api/notifications`
   - Distribuye las notificaciones a todos los clientes conectados

3. **Dashboard en Tiempo Real** (`websocket_web2/src/client.html`)
   - **PROTEGIDO POR LOGIN** 🔒 (credenciales de administrador)
   - Se conecta al servidor WebSocket
   - Recibe y muestra las notificaciones en tiempo real
   - Muestra estadísticas actualizadas de creaciones
   - Botón "Cerrar Sesión" en la esquina superior derecha

## 🚀 Configuración

### 1. Servidor WebSocket

```bash
cd app/websocket_service/websocket_web2
npm install
npm run dev  # o npm start
```

El servidor escuchará en `http://localhost:8080`

### 2. Panel Administrativo

Asegúrate de que `app.js` tenga la variable correcta:

```javascript
WEBSOCKET_URL: 'http://localhost:8080'
```

Esta URL debe coincidir con donde está ejecutándose el servidor WebSocket.

### 3. Dashboard (CON AUTENTICACIÓN)

Abre en el navegador:
```
http://localhost:8080/client.html
```

Se mostrará un formulario de login. Usa estas credenciales:

```
Usuario: admin
Contraseña: 12345
```

O:
```
Usuario: administrator
Contraseña: admin123
```

⚠️ **Cambiar estas credenciales antes de producción** (ver AUTENTICACION.md)

## 📨 Flujo de Notificaciones

### Cuando se crea un Producto

1. Usuario completa el formulario en el panel admin
2. Hace clic en "GUARDAR PRODUCTO"
3. Se envía POST a `/api/admin/productos/`
4. Si es exitoso, se envía notificación HTTP POST a `/api/notifications`:

```javascript
{
  type: 'PRODUCT_CREATED',
  data: {
    id: 1,
    nombre_comercial: 'Paracetamol 500mg',
    nombre_generico: 'Acetaminofén',
    precio: 5.50,
    mensaje: 'Nuevo producto: Paracetamol 500mg'
  },
  timestamp: '2025-11-14T10:30:45.123Z',
  user: 'admin_username'
}
```

5. El servidor WebSocket recibe esta notificación
6. La transmite a todos los clientes WebSocket conectados
7. El dashboard recibe el evento `PRODUCT_CREATED` y lo muestra

### Cuando se crea una Farmacia

Similar al anterior, pero con evento `PHARMACY_CREATED`

### Cuando se crea una Relación Producto-Farmacia

Similar al anterior, pero con evento `PRODUCT_PHARMACY_RELATION_CREATED`

## 📊 Dashboard - Características

- ✅ **Estadísticas en Tiempo Real**: Contador de productos, farmacias y relaciones creadas
- ✅ **Tres Secciones de Notificaciones**: Una para cada tipo de entidad
- ✅ **Detalles de Cada Notificación**: Muestra información específica de lo creado
- ✅ **Registro de Eventos**: Log técnico de todas las operaciones
- ✅ **Animaciones**: Deslizamiento suave de nuevas notificaciones
- ✅ **Conexión Visual**: Indicador de estado de conexión

## 🔌 Endpoints

### Servidor WebSocket

- **WebSocket**: `ws://localhost:8080/`
- **HTTP Notificaciones**: `POST /api/notifications`

### Body de Notificación

```json
{
  "type": "PRODUCT_CREATED|PHARMACY_CREATED|PRODUCT_PHARMACY_RELATION_CREATED",
  "data": { /* Datos específicos */ },
  "timestamp": "ISO8601 string",
  "user": "nombre de usuario"
}
```

## 🔐 Seguridad

Actualmente, el endpoint `/api/notifications` no valida autenticación. Para producción, se recomienda:

1. Agregar verificación de token JWT
2. Restringir a solicitudes del mismo origen
3. Implementar rate limiting

## 📱 Cliente WebSocket

El código JavaScript en `client.html` hace:

```javascript
// Conectar
const socket = new WebSocket('ws://localhost:8080');

// Recibir notificaciones
socket.onmessage = (event) => {
  const { event: type, data } = JSON.parse(event.data);
  
  if (type === 'PRODUCT_CREATED') {
    // Mostrar notificación de producto
  }
  // ... y así para otros tipos
};
```

## 🐛 Debugging

### En el Panel Admin

Abre la consola del navegador (F12) y verás logs como:

```
✅ Notificación enviada: PRODUCT_CREATED
{
  id: 1,
  nombre_comercial: 'Paracetamol',
  ...
}
```

### En el Dashboard

El registro de eventos muestra:
```
📌 [10:30:45] Evento recibido: PRODUCT_CREATED
📦 [10:30:45] Producto creado exitosamente
```

### En el Servidor WebSocket

Logs en la terminal:
```
POST /api/notifications 200
🟢 Cliente conectado
📨 Notificación enviada a 5 clientes
```

## 🔄 Reintentos y Fallback

Si el servidor WebSocket no está disponible:

- El panel admin mostrará un warning en la consola
- Las operaciones se completarán localmente
- Las notificaciones no se enviarán, pero los datos se guardarán

Cuando el servidor esté disponible de nuevo, solo se mostrarán notificaciones nuevas.

## 📝 Ejemplo de Uso Completo

1. **Abre el Dashboard**:
   ```bash
   http://localhost:8080/client.html
   ```

2. **Abre el Panel Admin**:
   ```bash
   Accede a app.html en tu navegador
   ```

3. **Crea un Producto**:
   - Navega a la pestaña "Admin"
   - Haz clic en "Crear Producto"
   - Completa el formulario
   - Haz clic en "GUARDAR PRODUCTO"

4. **Observa el Dashboard**:
   - Verás la notificación aparecer instantáneamente
   - El contador de "Productos Creados" aumentará
   - Los detalles del producto se mostrarán en la tarjeta

## 🚨 Troubleshooting

### No se ven notificaciones

1. Verifica que el servidor WebSocket esté corriendo:
   ```bash
   curl http://localhost:8080/api/notifications -X POST
   ```

2. Verifica que `WEBSOCKET_URL` en `app.js` sea correcto

3. Abre la consola del navegador y busca errores

### Conexión rechazada

1. Asegúrate que el puerto 8080 esté disponible
2. Intenta cambiar el puerto en `server.ts`

### Las notificaciones se envían pero no aparecen

1. Verifica que el cliente WebSocket esté conectado (indicador verde)
2. Abre la pestaña Red en Dev Tools (F12) y busca la conexión WebSocket
3. Revisa el mensaje en la consola del navegador

## 📚 Archivos Modificados

- `app/public/app.js`: Agregado método `sendWebSocketNotification()` y llamadas en `addAdminProducto()`, `addAdminFarmacia()`, `addAdminRelacion()`
- `websocket_service/websocket_web2/src/client.html`: Rediseñado completamente para mostrar notificaciones en tiempo real

## 🎯 Próximas Mejoras

- [ ] Sonido de notificación
- [ ] Notificaciones del navegador (Browser Push)
- [ ] Persistencia de notificaciones (base de datos)
- [ ] Filtrado de notificaciones
- [ ] Exportación de logs
- [ ] Integración con email

---

**Creado**: 14 de Noviembre, 2025
**Versión**: 1.0.0
