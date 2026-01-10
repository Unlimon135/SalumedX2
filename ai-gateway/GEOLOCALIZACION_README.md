# Geolocalización - Farmacias Cercanas

## 📍 Descripción

Implementación de geolocalización para mostrar farmacias cercanas al usuario basándose en su ubicación GPS.

## 🏗️ Arquitectura

```
Frontend (JavaScript/Vue.js)
 └─ Solicita ubicación al usuario (navigator.geolocation)
 └─ Envía lat/lng con cada mensaje al backend
 
Backend (Ruby/Sinatra)
 ├─ Recibe coordenadas (user_lat, user_lng)
 ├─ Consulta farmacias desde GraphQL
 ├─ Calcula distancia usando Haversine
 └─ Devuelve farmacias ordenadas por cercanía
```

## 📦 Componentes Implementados

### 1. Frontend (chat.js)
- **Captura de geolocalización**: `requestLocation()`
- **Envío de coordenadas**: Incluye `user_lat` y `user_lng` en cada mensaje
- **Indicador visual**: Muestra estado del GPS en el header
- **Manejo de errores**: Gestiona permisos denegados y errores de ubicación

### 2. Backend Services

#### `FarmaciaService` (farmacia_service.rb)
```ruby
class FarmaciaService
  # Buscar farmacias cercanas
  def buscar_cercanas(user_lat, user_lng, producto_nombre: nil, limit: 5)
    # 1. Obtener farmacias desde GraphQL
    # 2. Filtrar por producto (opcional)
    # 3. Calcular distancia con Haversine
    # 4. Ordenar y limitar resultados
  end
  
  # Fórmula de Haversine para calcular distancia
  def calcular_distancia(lat1, lng1, lat2, lng2)
    # Retorna distancia en kilómetros
  end
end
```

#### `BuscarFarmaciaCercana` (mcp/queries/buscar_farmacia_cercana.rb)
```ruby
module MCP
  class BuscarFarmaciaCercana
    def self.execute(params, token, context = {})
      # Parámetros:
      # - user_lat: Latitud del usuario
      # - user_lng: Longitud del usuario
      # - producto: Nombre del producto (opcional)
      # - limit: Número de resultados (default: 5)
    end
  end
end
```

### 3. Agent AI (agent.rb)
- **Detección de consultas**: Detecta palabras clave como "farmacia", "cerca", "dónde comprar"
- **Contexto de ubicación**: Pasa coordenadas del usuario a las herramientas MCP
- **Integración fluida**: Se ejecuta automáticamente cuando se detecta la intención

## 🎯 Casos de Uso

### Ejemplo 1: Farmacias cercanas
```
Usuario: "¿Dónde hay farmacias cerca?"
AI: Muestra las 5 farmacias más cercanas con distancias
```

### Ejemplo 2: Producto específico
```
Usuario: "¿Dónde puedo comprar paracetamol?"
AI: Muestra farmacias cercanas que tengan paracetamol en stock
```

### Ejemplo 3: Consulta general
```
Usuario: "Necesito una farmacia"
AI: Muestra farmacias más cercanas ordenadas por distancia
```

## 🔧 Configuración

### Permisos del Navegador
El usuario debe permitir el acceso a la ubicación cuando se le solicite.

### Campos Requeridos en BD
Las farmacias deben tener los siguientes campos:
- `lat` o `latitude`: Latitud
- `lng` o `longitude`: Longitud
- `nombre`: Nombre de la farmacia
- `direccion`: Dirección de la farmacia
- `productos`: Array de productos disponibles (opcional)

## 📊 Fórmula de Haversine

Calcula la distancia entre dos puntos en una esfera (la Tierra):

```ruby
a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlng/2)
c = 2 × atan2(√a, √(1−a))
distancia = radio_tierra × c
```

Donde:
- `radio_tierra` = 6371 km
- `Δlat` = lat2 - lat1
- `Δlng` = lng2 - lng1

**Precisión**: ~99.5% para distancias < 1000km

## 🎨 UI/UX

### Indicador de GPS
- **Verde** (📍): GPS activo, ubicación disponible
- **Rojo** (📍): GPS inactivo, ubicación no disponible
- **Click**: Reintentar obtener ubicación

### Mensajes del Sistema
- Notificación cuando se activa la ubicación
- Advertencia cuando no se puede obtener ubicación
- Mensajes informativos sobre el estado del GPS

## 🔐 Privacidad

- La ubicación solo se envía al backend cuando el usuario consulta farmacias
- No se almacena la ubicación en la base de datos
- El usuario puede denegar permisos en cualquier momento
- La ubicación se actualiza cada 5 minutos (configurable)

## 🚀 Activación

1. Abrir chat.html
2. Permitir acceso a la ubicación cuando se solicite
3. El indicador GPS debe aparecer en verde
4. Preguntar: "¿Dónde hay farmacias cerca?"

## 🐛 Troubleshooting

### GPS no se activa
- Verificar permisos del navegador
- Usar HTTPS (geolocalización no funciona en HTTP)
- Verificar que el dispositivo tenga GPS activo

### No muestra farmacias
- Verificar que las farmacias tengan coordenadas en la BD
- Verificar que el GraphQL endpoint esté funcionando
- Revisar logs del backend para errores

### Distancias incorrectas
- Verificar que las coordenadas estén en formato decimal (no DMS)
- Verificar que lat/lng no estén invertidos

## 📝 Mejoras Futuras

- [ ] Cache de ubicación para reducir llamadas GPS
- [ ] Mapa interactivo con marcadores de farmacias
- [ ] Filtros avanzados (horario, servicios, etc.)
- [ ] Rutas desde ubicación actual a farmacia
- [ ] Notificaciones de farmacias nuevas cercanas
- [ ] Compartir ubicación de farmacia específica
