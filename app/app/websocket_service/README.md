## 🎯 Sistema de Notificaciones WebSocket - SaluMedX

Este directorio contiene el servidor WebSocket que maneja notificaciones en tiempo real para el sistema SaluMedX.

### 📁 Estructura

```
websocket_service/
├── websocket_web2/              # Servidor Node.js con TypeScript
│   ├── src/
│   │   ├── server.ts           # Servidor Express + WebSocket
│   │   ├── client.html         # Dashboard de notificaciones
│   │   ├── services/
│   │   │   ├── notification.service.ts    # Patrón Observer
│   │   │   └── websocket.service.ts       # Patrón Singleton
│   │   └── utils/
│   │       └── logger.ts       # Utilidad de logging
│   ├── package.json
│   └── tsconfig.json
├── test-notifications.ps1       # Script de prueba en PowerShell
├── START_SERVER.ps1            # Script para iniciar servidor
└── INTEGRACION_WEBSOCKET.md    # Documentación completa
```

### 🚀 Inicio Rápido

**Terminal 1: Iniciar el servidor**
```bash
cd websocket_web2
npm install
npm run dev
```

**Navegador: Ver dashboard**
```
http://localhost:8080/client.html
```

**Terminal 2: Enviar notificaciones de prueba**
```powershell
cd ..
.\test-notifications.ps1
```

### 🔌 API

**Endpoint para enviar notificaciones:**
```
POST http://localhost:8080/api/notifications
Content-Type: application/json

{
  "type": "PRODUCT_CREATED",
  "data": {
    "id": 1,
    "nombre_comercial": "Producto Ejemplo",
    "precio": 10.99,
    "mensaje": "Descripción del evento"
  }
}
```

### 📊 Eventos Soportados

1. **PRODUCT_CREATED** - Se dispara cuando se crea un producto en app.html
2. **PHARMACY_CREATED** - Se dispara cuando se crea una farmacia  
3. **PRODUCT_PHARMACY_RELATION_CREATED** - Se dispara cuando se crea una relación producto-farmacia

### ✅ Características

- ✅ Conexión WebSocket en tiempo real
- ✅ Broadcast a múltiples clientes simultáneamente
- ✅ Logging detallado para debug
- ✅ Dashboard interactivo con estadísticas
- ✅ Integración automática con app.html (admin panel)
- ✅ Manejo robusto de errores
- ✅ Soporte para TypeScript

### 🔗 Integración con App.html

El archivo `../public/app.js` contiene:

```javascript
async sendWebSocketNotification(type, data) {
  await axios.post(`${this.WEBSOCKET_URL}/api/notifications`, {
    type: type,
    data: data,
    timestamp: new Date().toISOString(),
    user: this.username
  });
}
```

Esta función se llama automáticamente en:
- `addAdminProducto()` - Envía PRODUCT_CREATED
- `addAdminFarmacia()` - Envía PHARMACY_CREATED  
- `addAdminRelacion()` - Envía PRODUCT_PHARMACY_RELATION_CREATED

### 🧪 Troubleshooting

**"Address already in use :::8080"**
```powershell
Get-Process -Name node | Stop-Process -Force
```

**Dashboard no recibe notificaciones**
1. Verifica que el servidor está corriendo: `http://localhost:8080/`
2. Abre la consola del navegador (F12) para ver logs
3. Verifica los logs del servidor en la terminal

**WebSocket no se conecta**
- Asegúrate que el puerto 8080 está disponible
- Verifica que el servidor Express está sirviendo `/client.html`

### 📝 Logs Disponibles

El servidor registra automáticamente:
```
[INFO] 🚀 WebSocketServer inicializado
[INFO] 🔔 NotificationService inicializado
[INFO] ✅ Nueva suscripción registrada. Total: 1
✅ Servidor escuchando en http://localhost:8080
📊 WebSocket disponible en ws://localhost:8080
[INFO] 🟢 Cliente conectado. Total clientes: 1
[INFO] 📨 Notificación recibida: PRODUCT_CREATED
[INFO] 📤 Broadcasting evento: PRODUCT_CREATED a 1 clientes
[INFO] ✅ Evento 'PRODUCT_CREATED' enviado a 1 clientes
```

### 🔒 Seguridad

- El dashboard no requiere autenticación (acceso público)
- El admin panel (`app.html`) requiere login con credenciales
- Las notificaciones se envían solo a clientes conectados al WebSocket
- No hay persistencia de datos en base de datos

### 📚 Documentación Adicional

Ver `INTEGRACION_WEBSOCKET.md` para:
- Flujo completo de funcionamiento
- Detalles técnicos de implementación
- Ejemplos avanzados
- Guía de desarrollo

---

**Estado:** ✅ Completamente funcional y listo para producción
**Última actualización:** 14 de noviembre de 2025
