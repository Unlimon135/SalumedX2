# Diagrama de Flujo - Sistema de Notificaciones en Tiempo Real

## 1️⃣ FLUJO DE CREACIÓN DE PRODUCTO

```
┌─────────────────────────────────────────────────────────────────┐
│                    PANEL ADMINISTRATIVO (app.html)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Usuario:                                                       │
│  1. Completa formulario de producto                            │
│  2. Hace clic en "GUARDAR PRODUCTO"                            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────┐       │
│  │ Llamada: addAdminProducto()                         │       │
│  ├─────────────────────────────────────────────────────┤       │
│  │ 1. Valida campos                                    │       │
│  │ 2. POST a /api/admin/productos/                    │       │
│  │ 3. Si éxito:                                       │       │
│  │    - Actualiza lista local (adminData.productos)   │       │
│  │    - Muestra mensaje de éxito                      │       │
│  │    - Llama sendWebSocketNotification()             │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ⬇️
                   
┌─────────────────────────────────────────────────────────────────┐
│              MÉTODO: sendWebSocketNotification()                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Prepara la notificación:                                       │
│  {                                                              │
│    type: 'PRODUCT_CREATED',                                    │
│    data: {                                                     │
│      id: created.id,                                           │
│      nombre_comercial: created.nombre_comercial,               │
│      nombre_generico: created.nombre_generico,                 │
│      precio: created.precio,                                   │
│      mensaje: 'Nuevo producto: ...'                            │
│    },                                                           │
│    timestamp: '2025-11-14T10:30:45Z',                          │
│    user: 'username'                                            │
│  }                                                              │
│                                                                 │
│  POST a: http://localhost:8080/api/notifications               │
│                                                                 │
│  ✅ Éxito:     Log en consola "✅ Notificación enviada"        │
│  ❌ Error:     Log en consola "⚠ No se pudo enviar"           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ⬇️
                   
┌─────────────────────────────────────────────────────────────────┐
│            SERVIDOR WEBSOCKET (localhost:8080)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Endpoint: POST /api/notifications                             │
│                                                                 │
│  Recibe la notificación:                                        │
│  1. Extrae type y data del body                               │
│  2. Llama a NotificationService.publish(type, data)           │
│                                                                 │
│  NotificationService (patrón Observer):                        │
│  1. Itera todos los subscribers                               │
│  2. Ejecuta cada subscriber con (type, data)                  │
│                                                                 │
│  WebSocketServerService (patrón Broadcast):                    │
│  1. Recibe la notificación del observer                       │
│  2. Itera todos los clientes WebSocket conectados            │
│  3. Si cliente.readyState === OPEN:                          │
│     - Envía JSON { event: type, data: data }                 │
│                                                                 │
│  ✅ Response: { message: "Notificación enviada" }             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ⬇️
                   
┌─────────────────────────────────────────────────────────────────┐
│             DASHBOARD EN TIEMPO REAL (client.html)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Conexión WebSocket: ws://localhost:8080                       │
│                                                                 │
│  socket.onmessage = (event) => {                              │
│    const { event: type, data } = JSON.parse(event.data)      │
│                                                                 │
│    if (type === 'PRODUCT_CREATED') {                         │
│      1. counts.products++                                     │
│      2. updateStats() → Actualiza contador visual             │
│      3. addNotificationCard() → Muestra tarjeta               │
│      4. Log de evento en registro                             │
│    }                                                            │
│  }                                                              │
│                                                                 │
│  Visual del Dashboard:                                         │
│  ┌─────────────────────────┐                                  │
│  │ 📦 Productos Creados: 1 │                                  │
│  ├─────────────────────────┤                                  │
│  │ ✨ Notificación nueva   │                                  │
│  │ 📦 Paracetamol 500mg    │                                  │
│  │ ID: 1                   │                                  │
│  │ Precio: $5.50           │                                  │
│  └─────────────────────────┘                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

```

---

## 2️⃣ FLUJO DE CREACIÓN DE FARMACIA

```
PANEL ADMIN → addAdminFarmacia() → sendWebSocketNotification('PHARMACY_CREATED', {...})
    ⬇️
SERVIDOR (POST /api/notifications) → NotificationService → broadcast
    ⬇️
DASHBOARD → socket.onmessage → counts.pharmacies++ → updateStats() → addNotificationCard()
```

---

## 3️⃣ FLUJO DE CREACIÓN DE RELACIÓN PRODUCTO-FARMACIA

```
PANEL ADMIN → addAdminRelacion() → sendWebSocketNotification('PRODUCT_PHARMACY_RELATION_CREATED', {...})
    ⬇️
SERVIDOR (POST /api/notifications) → NotificationService → broadcast
    ⬇️
DASHBOARD → socket.onmessage → counts.relations++ → updateStats() → addNotificationCard()
```

---

## 🔄 ARQUITECTURA GENERAL

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│                    COMUNICACIÓN EN TIEMPO REAL                       │
│                                                                      │
├────────────────────────┬──────────────────┬─────────────────────────┤
│                        │                  │                         │
│   PANEL ADMIN          │   SERVIDOR WS    │   DASHBOARD             │
│   (app.html)           │   (server.ts)    │   (client.html)         │
│                        │                  │                         │
│  1. Usuario crea    ┌──▶ POST /api/     ┌─▶ Recibe por WS          │
│     datos           │    notifications   │                         │
│                     │                    │   Actualiza UI           │
│  2. click en       │    NotificationService                       │
│     "GUARDAR"       │    (Observer)      │   - Contadores          │
│                     │                    │   - Tarjetas            │
│  3. Validación   │    WebSocketServer │   - Log                  │
│     y creación      │    (Broadcast)     │                         │
│                     │                    │   Persiste en RAM       │
│  4. Llamada HTTP ├──────────────────────┤                         │
│     POST            │                    │                         │
│                     │                    │                         │
│  5. Notificación  │                    │                         │
│     al servidor     │                    │                         │
│                     │                    │                         │
│  Resultado:      │  Resultado:        │  Resultado:             │
│  ✅ Datos        │  ✅ Recibe y      │  ✅ Notificación        │
│  guardados       │  distribuye        │  visible al              │
│                 │                    │  instante                │
│                 │                    │                         │
└────────────────────────┴──────────────────┴─────────────────────────┘

```

---

## 📊 SECUENCIA TEMPORAL

```
TIEMPO    PANEL ADMIN          SERVIDOR WS          DASHBOARD
─────────────────────────────────────────────────────────────────

t=0ms     Usuario hace click
          en "GUARDAR PRODUCTO"
          ↓
          Validación local
          ↓
t=50ms    POST /api/admin/
          productos/
          ─────────────────────▶ Recibe en REST API
                                ↓
t=100ms   Espera respuesta       Procesa en DB
                                ↓
t=150ms   Respuesta exitosa      Retorna {"id": 1, ...}
          ←─────────────────────
          ↓
t=155ms   Actualiza lista local
          ↓
t=160ms   Llama sendWebSocket
          Notification()
          ↓
t=165ms   POST /api/notifications
          con datos completos
          ─────────────────────▶ Recibe notificación
t=170ms                         ↓
                                NotificationService.publish()
                                ↓
                                Broadcast a 5 clientes WS
                                ↓
t=175ms                         Envía evento a Dashboard
          ┌──────────────────────▶ Recibe evento WS
          │                       ↓
t=180ms   │                       Parsea JSON
          │                       ↓
          │                       Actualiza counts.products
          │                       ↓
t=185ms   │                       updateStats() - actualiza contador
          │                       ↓
t=190ms   │                       addNotificationCard() - crea tarjeta
          │                       ↓
t=200ms   │                       log() - registra en log
          │                       ↓
          │                       ✅ Notificación visible en dashboard
          │
          └─────────────────────────────────────────────

TOTAL: ~200ms desde que el usuario hace clic hasta que ve la notificación

```

---

## 🔌 ESTADO DE CONEXIONES

```
                                  ┌─────────────────┐
                                  │  SERVIDOR WS    │
                                  │   (8080)        │
                                  │                 │
                                  │  - HTTP API     │
                                  │  - WebSocket    │
                                  │  - Broadcast    │
                                  └────────┬────────┘
                                           ▲
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    │ REST POST            │ WebSocket Upgrade   │
                    │ /api/notifications   │ Connection          │
                    │                      │                      │
                    ▼                      ▼                      ▼
            ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
            │ PANEL ADMIN  │      │ DASHBOARD 1  │      │ DASHBOARD 2  │
            │ (app.html)   │      │(client.html) │      │(client.html) │
            │              │      │              │      │              │
            │ Envía notif. │      │ Recibe notif.│      │ Recibe notif.│
            │ cuando crea  │      │ Actualiza UI │      │ Actualiza UI │
            │ datos        │      │              │      │              │
            └──────────────┘      └──────────────┘      └──────────────┘

Múltiples dashboards pueden estar viendo notificaciones simultáneamente
```

---

## 🎯 CASOS DE USO

### Caso 1: Un administrador crea un producto

```
Admin A abre Panel → Crea Producto X → Se envía notificación
                                       ↓
                            Todos los dashboards conectados
                            ven "Producto X creado"
```

### Caso 2: Múltiples administradores crean datos simultáneamente

```
Admin A: Crea Producto 1 ──┐
                           │ Ambas notificaciones
Admin B: Crea Farmacia 1 ──┤ llegan al servidor en
                           │ ~50ms de diferencia
                           ↓
                    Dashboard ve:
                    "Producto 1 creado"
                    "Farmacia 1 creada"
                    (en tiempo real)
```

### Caso 3: Múltiples dashboards monitorean

```
Dashboard 1 ─┐
             │ Todos reciben
Dashboard 2 ─┤ las MISMAS notificaciones
             │ al MISMO tiempo
Dashboard N ─┘ (comunicación 1-a-muchos)
```

---

## ⚠️ MANEJO DE ERRORES

```
┌─────────────────────────────────────────┐
│ Panel Admin intenta enviar notificación │
└────────────────┬────────────────────────┘
                 │
                 ▼
      ┌──────────────────────┐
      │ ¿Servidor WS        │
      │ disponible?         │
      └──────────────────────┘
           │         │
        SÍ │         │ NO
           ▼         ▼
    ✅ Éxito    ⚠️ Warning
    Log OK      Console.warn()
    Notif.      No interrumpe
    distribuida  operación
               (datos se guardan
                igual)

```

---

## 📈 ESCABILIDAD

```
Configuración Actual:
- Clientes: Unlimited (WebSocket escalable)
- Mensajes/seg: 100+ (Server puede manejar)
- Latencia: ~50-200ms (muy aceptable)
- Tamaño msg: <1KB (eficiente)

Para Producción:
- Agregar rate limiting
- Implementar autenticación JWT
- Monitorear memoria del servidor
- Configurar HTTPS + WSS
- Agregar base de datos de logs
```

---

**Diagrama Version**: 1.0
**Creado**: 14 de Noviembre, 2025
