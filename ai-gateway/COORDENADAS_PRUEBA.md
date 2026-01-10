# 📍 Coordenadas de Prueba para Geolocalización

## Ciudades de Prueba (Ecuador)

### Quito (Capital)
```ruby
user_lat = -0.1807
user_lng = -78.4678
```

### Guayaquil
```ruby
user_lat = -2.1894
user_lng = -79.8886
```

### Cuenca
```ruby
user_lat = -2.9001
user_lng = -79.0059
```

## Ciudades de Prueba (Perú)

### Lima (Capital)
```ruby
user_lat = -12.0464
user_lng = -77.0428
```

### Cusco
```ruby
user_lat = -13.5319
user_lng = -71.9675
```

### Arequipa
```ruby
user_lat = -16.4090
user_lng = -71.5375
```

## Ciudades de Prueba (Colombia)

### Bogotá (Capital)
```ruby
user_lat = 4.7110
user_lng = -74.0721
```

### Medellín
```ruby
user_lat = 6.2442
user_lng = -75.5812
```

### Cali
```ruby
user_lat = 3.4516
user_lng = -76.5320
```

## Ciudades de Prueba (España)

### Madrid (Capital)
```ruby
user_lat = 40.4168
user_lng = -3.7038
```

### Barcelona
```ruby
user_lat = 41.3851
user_lng = 2.1734
```

### Valencia
```ruby
user_lat = 39.4699
user_lng = -0.3763
```

## Cómo Usar en Tests

### En test_geolocation.rb
```ruby
# Cambiar estas líneas:
user_lat = -12.0464  # Cambiar a coordenadas de tu ciudad
user_lng = -77.0428
```

### En Postman/Thunder Client
```json
{
  "message": "¿Dónde hay farmacias cerca?",
  "user_lat": -12.0464,
  "user_lng": -77.0428
}
```

### En JavaScript Console (Browser)
```javascript
// Simular ubicación manualmente
app.userLocation = {
  latitude: -12.0464,
  longitude: -77.0428,
  accuracy: 100
};
```

## Distancias de Referencia

Para validar cálculos:

### Quito → Guayaquil
- Distancia real: ~280 km
- Haversine: ~280.5 km

### Lima → Cusco
- Distancia real: ~1,100 km
- Haversine: ~1,105 km

### Madrid → Barcelona
- Distancia real: ~625 km
- Haversine: ~623 km

## Obtener Coordenadas Reales

### Opción 1: Google Maps
1. Abrir Google Maps
2. Click derecho en el punto deseado
3. Copiar coordenadas

### Opción 2: Navegador
```javascript
navigator.geolocation.getCurrentPosition(pos => {
  console.log(`Lat: ${pos.coords.latitude}`);
  console.log(`Lng: ${pos.coords.longitude}`);
});
```

### Opción 3: APIs
```bash
# IP Geolocation
curl "https://ipapi.co/json/"

# OpenStreetMap
curl "https://nominatim.openstreetmap.org/search?q=Lima&format=json"
```

## Formato de Coordenadas

### ✅ CORRECTO (Decimal)
```ruby
lat = -12.0464   # Grados decimales
lng = -77.0428
```

### ❌ INCORRECTO (DMS - Grados, Minutos, Segundos)
```ruby
lat = "12°02'47\"S"  # NO usar este formato
lng = "77°02'34\"W"
```

## Conversión DMS → Decimal

Si tienes coordenadas en formato DMS:

```ruby
def dms_to_decimal(degrees, minutes, seconds, direction)
  decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)
  decimal *= -1 if ['S', 'W'].include?(direction)
  decimal
end

# Ejemplo: 12°02'47"S, 77°02'34"W
lat = dms_to_decimal(12, 2, 47, 'S')  # -12.0464
lng = dms_to_decimal(77, 2, 34, 'W')  # -77.0428
```

## Rangos Válidos

### Latitud
- Rango: -90 a +90
- Norte: Positivo (+)
- Sur: Negativo (-)

### Longitud
- Rango: -180 a +180
- Este: Positivo (+)
- Oeste: Negativo (-)

## Ejemplos de Coordenadas Especiales

### Polo Norte
```ruby
lat = 90.0
lng = 0.0
```

### Polo Sur
```ruby
lat = -90.0
lng = 0.0
```

### Línea del Ecuador
```ruby
lat = 0.0
lng = -78.4678  # Quito está casi en el ecuador
```

### Meridiano de Greenwich
```ruby
lat = 51.4779  # Greenwich, Londres
lng = 0.0
```

## 🧪 Test Rápido

Probar cálculo de distancia:

```ruby
service = FarmaciaService.new
dist = service.send(:calcular_distancia, 
  -12.0464, -77.0428,  # Lima
  -0.1807, -78.4678    # Quito
)
puts "Distancia Lima-Quito: #{dist.round(2)} km"
# Resultado esperado: ~1,750 km
```
