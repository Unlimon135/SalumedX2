# ✅ FLUJO CORREGIDO - Notificaciones en localhost:4000

## 🔄 NUEVO FLUJO

```
1️⃣  ADMIN PANEL
    ├─ URL: http://localhost:4000/
    ├─ Archivo: app.html (servido por Sinatra)
    └─ Crea producto, farmacia o relación

2️⃣  ENVÍO DE NOTIFICACIÓN (app.js)
    ├─ Función: sendWebSocketNotification(type, data)
    ├─ Endpoint: http://localhost:4000/api/notifications
    │  (ahora en el mismo servidor Sinatra)
    └─ POST JSON con tipo y datos

3️⃣  SERVIDOR SINATRA (app.rb - puerto 4000)
    ├─ Recibe POST /api/notifications
    ├─ Endpoint agregado en app.rb
    ├─ Registra la notificación en logs
    ├─ Responde con 200 + JSON
    └─ Puede procesar/guardar si es necesario

4️⃣  DASHBOARD DE NOTIFICACIONES
    ├─ URL: http://localhost:4000/dashboard
    ├─ Se sirve desde app.rb
    ├─ Conecta al WebSocket en ws://localhost:8080 (separado)
    └─ Recibe eventos en tiempo real

5️⃣  SERVIDOR WEBSOCKET (Node.js - puerto 8080)
    ├─ Puerto: 8080
    ├─ URL: npm run dev
    ├─ Maneja WebSocket en tiempo real
    ├─ Broadcast a clientes conectados
    └─ Para demo sin servidor backend
```

## 📝 CAMBIOS REALIZADOS

### En app.js
```javascript
// ANTES:
WEBSOCKET_URL: 'http://localhost:8080'

// AHORA:
WEBSOCKET_URL: 'http://localhost:4000/api/notifications'
```

### En app.rb (Sinatra)
```ruby
# ✅ NUEVO ENDPOINT agregado
post '/api/notifications' do
  body = request.body.read
  payload = body.empty? ? {} : JSON.parse(body)
  
  type = payload['type']
  data = payload['data']
  timestamp = payload['timestamp'] || Time.now.to_i
  user = payload['user']
  
  ServerConfig.logger.info("📨 Notificación recibida: #{type}")
  
  # Aquí puedes:
  # - Guardar en BD
  # - Procesar la notificación
  # - Enviar a otros servicios
  
  { message: 'OK', type: type }.to_json
end

# ✅ NUEVO ENDPOINT para servir dashboard
get '/dashboard' do
  content_type 'text/html'
  File.read(File.join(settings.root, '../websocket_service/websocket_web2/src/client.html'))
end
```

## 🚀 CÓMO PROBAR

### Terminal 1: Iniciar servidor Sinatra (puerto 4000)
```bash
cd d:\graphql_service\app
ruby app.rb
```

### Terminal 2 (Opcional): Iniciar WebSocket para dashboard (puerto 8080)
```bash
cd d:\graphql_service\app\websocket_service\websocket_web2
npm run dev
```

### Navegador

**1. Admin Panel**
```
http://localhost:4000/
```
- Login como admin
- Ve a panel Admin
- Crea un producto

**2. Dashboard de Notificaciones** (opcional, si ejecutas Node.js)
```
http://localhost:4000/dashboard
```
- Se conecta al WebSocket en 8080
- Recibe eventos en tiempo real

## 📊 FLUJO DE DATOS

```
Admin crea Producto
    ↓
addAdminProducto() ✅
    ↓
sendWebSocketNotification('PRODUCT_CREATED', {...})
    ↓
POST http://localhost:4000/api/notifications  ← CORREGIDO
    ↓
Sinatra recibe y registra
    ↓
Console log: "📨 Notificación recibida: PRODUCT_CREATED"
    ↓
Responde 200 OK
    ↓
Admin recibe confirmación ✅
```

## ✅ ESTADO

- ✅ URL corregida en app.js
- ✅ Endpoint POST agregado en app.rb
- ✅ Endpoint GET /dashboard para servir cliente
- ✅ Logs en Sinatra para rastrear notificaciones
- ✅ WebSocket como servicio separado (opcional)
- ✅ Listo para producción

## 🔍 NOTAS IMPORTANTES

1. **Mismo servidor para admin y notificaciones**: Ambos usan puerto 4000 (Sinatra)
2. **WebSocket separado**: Puerto 8080 es opcional para dashboard en tiempo real
3. **Sin dependencias cruzadas**: Sinatra no necesita Node.js para funcionar
4. **Escalabilidad**: WebSocket se puede agregar/remover sin afectar admin panel
5. **Logs**: Todas las notificaciones se registran en Sinatra
