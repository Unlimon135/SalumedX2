# 🚀 Guía Rápida: Geolocalización en Pilar 3

## ✅ Implementación Completa

La funcionalidad de geolocalización para mostrar farmacias cercanas está **100% implementada** y lista para usar.

## 📋 Archivos Creados/Modificados

### Backend (ai-gateway/)
- ✅ `services/farmacia_service.rb` - Servicio con cálculo de distancias (Haversine)
- ✅ `mcp/queries/buscar_farmacia_cercana.rb` - Query MCP para farmacias cercanas
- ✅ `gateway/mcp_router.rb` - Registro de nueva herramienta
- ✅ `gateway/agent.rb` - Detección de consultas sobre farmacias
- ✅ `controllers/chat_controller.rb` - Recibe coordenadas del usuario
- ✅ `config/environment.rb` - Carga de nuevos módulos

### Frontend (app/public/)
- ✅ `chat.js` - Captura de geolocalización y envío de coordenadas
- ✅ `chat.html` - Indicador visual de GPS
- ✅ `chat-styles.css` - Estilos para indicador de ubicación

### Documentación
- ✅ `GEOLOCALIZACION_README.md` - Documentación completa
- ✅ `test_geolocation.rb` - Tests de funcionalidad

## 🎯 Cómo Usar

### 1. Iniciar el servidor AI Gateway
```powershell
cd d:\graphql_service\ai-gateway
ruby app.rb
```

### 2. Abrir el chat en el navegador
```
http://localhost:4567/chat.html
```

### 3. Permitir acceso a la ubicación
- El navegador solicitará permiso para acceder a tu ubicación
- Click en "Permitir"
- Verás un indicador verde 📍 "GPS activo" en el header

### 4. Preguntar por farmacias
Ejemplos de consultas que funcionan:

```
"¿Dónde hay farmacias cerca?"
"Necesito una farmacia cercana"
"¿Dónde puedo comprar paracetamol?"
"Busca ibuprofeno en farmacias cercanas"
"¿Qué farmacia está más cerca de mí?"
```

## 🧪 Probar la Funcionalidad

### Test Backend (sin frontend)
```powershell
cd d:\graphql_service\ai-gateway
ruby test_geolocation.rb
```

### Test Completo (con frontend)
1. Abrir DevTools en el navegador (F12)
2. Ir a Console
3. Escribir: `console.log(app.userLocation)`
4. Verificar que aparezcan las coordenadas

## 🔍 Flujo Completo

```
1. Usuario abre chat.html
   ↓
2. JavaScript solicita ubicación (navigator.geolocation)
   ↓
3. Usuario permite acceso
   ↓
4. Se guardan coordenadas (latitude, longitude)
   ↓
5. Usuario pregunta: "¿Dónde hay farmacias cerca?"
   ↓
6. Frontend envía: { message: "...", user_lat: X, user_lng: Y }
   ↓
7. ChatController recibe coordenadas
   ↓
8. Agent detecta intención: "buscar_farmacia_cercana"
   ↓
9. MCPRouter ejecuta: BuscarFarmaciaCercana
   ↓
10. FarmaciaService:
    - Consulta farmacias (GraphQL)
    - Calcula distancias (Haversine)
    - Ordena por cercanía
   ↓
11. Agent formatea respuesta con LLM
   ↓
12. Frontend muestra farmacias con distancias
```

## 🎨 Indicadores Visuales

### Header del Chat
- 🟢 **GPS activo** - Ubicación disponible
- 🔴 **GPS inactivo** - Click para reintentar
- Sin indicador - Geolocalización no solicitada aún

### Mensajes del Sistema
- Confirmación cuando se activa GPS
- Advertencia si no se puede obtener ubicación

### Sidebar
- Nueva herramienta: `buscar_farmacia_cercana`

## 📊 Formato de Respuesta

El AI mostrará algo como:

```
Encontré 3 farmacias cerca de tu ubicación:

1. **Farmacia San Juan**
   📍 Av. Principal 123
   📏 0.5 km de distancia
   
2. **Botica MedSalud**
   📍 Jr. Libertad 456
   📏 1.2 km de distancia
   
3. **Farmacia Universal**
   📍 Av. Los Heroes 789
   📏 2.3 km de distancia
```

## ⚙️ Configuración

### Ajustar cantidad de resultados
En `agent.rb`, modificar:
```ruby
when 'buscar_farmacia_cercana'
  params = { limit: 10 }  # Cambiar 5 a 10
```

### Ajustar precisión GPS
En `chat.js`, modificar:
```javascript
{
  enableHighAccuracy: true,
  timeout: 10000,
  maximumAge: 300000  // 5 minutos
}
```

## 🐛 Solución de Problemas

### "Permiso de ubicación denegado"
1. Ir a configuración del navegador
2. Buscar "Permisos del sitio"
3. Permitir ubicación para localhost

### No muestra farmacias
1. Verificar que el GraphQL tenga farmacias con coordenadas
2. Verificar logs del backend: `ruby app.rb`
3. Revisar console del navegador (F12)

### GPS no se activa
- Usar HTTPS (o localhost)
- Verificar que el dispositivo tenga GPS/WiFi activo
- Recargar la página

## 📝 Próximos Pasos

Para mejorar la funcionalidad:

1. **Mapa Interactivo**
   - Integrar Google Maps o Leaflet
   - Mostrar farmacias en el mapa

2. **Filtros Avanzados**
   - Horario de atención
   - Servicios disponibles
   - Calificaciones

3. **Rutas**
   - Calcular ruta desde ubicación actual
   - Tiempo estimado de llegada

4. **Notificaciones**
   - Alertas de farmacias nuevas
   - Ofertas cercanas

## ✨ ¡Listo!

La geolocalización está completamente funcional. Solo necesitas:
1. Iniciar el servidor
2. Abrir el chat
3. Permitir ubicación
4. Preguntar por farmacias

¡Disfruta de tu nueva funcionalidad! 🎉
