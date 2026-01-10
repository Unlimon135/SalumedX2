# 🔧 Solución: Error 429 - Cuota de Gemini Excedida

## ❌ Problema

```
Error 429: You exceeded your current quota
Quota exceeded for metric: generativelanguage.googleapis.com/generate_content_free_tier_requests
limit: 20, model: gemini-2.5-flash
Please retry in 51.143967712s
```

## 📊 ¿Qué significa?

El plan gratuito de Gemini tiene límites:
- **15 RPM** (Requests Per Minute) - 15 peticiones por minuto
- **1,500 RPD** (Requests Per Day) - 1,500 peticiones por día
- **1 millón tokens por minuto** (input)

Si superas estos límites, debes esperar.

## ✅ Soluciones

### 1. **Esperar el tiempo indicado** (Más simple)

El error dice: "Please retry in 51.143967712s"

Espera ~1 minuto y prueba de nuevo.

### 2. **Cambiar a modelo más reciente** (Recomendado)

Edita [llm/gemini_adapter.rb](d:\graphql_service\ai-gateway\llm\gemini_adapter.rb):

```ruby
# Línea 8 - Cambiar modelo
@model = 'gemini-2.0-flash-exp'  # Modelo experimental más rápido
# o
@model = 'gemini-1.5-flash'      # Modelo estable con más cuota
```

### 3. **Obtener API Key Pro** (Para producción)

1. Ve a: https://aistudio.google.com/apikey
2. Crea un nuevo proyecto con facturación
3. Obtén una API Key de pago
4. Actualiza `.env`:
```env
GEMINI_API_KEY=tu_nueva_api_key_aqui
```

**Límites con plan de pago:**
- 360 RPM
- 30,000 RPD
- Más estable

### 4. **Usar caché local** (Avanzado)

Agregar sistema de caché para respuestas frecuentes:

```ruby
# En agent.rb
@cache = {}

def process_message(message)
  cache_key = Digest::MD5.hexdigest(message.downcase)
  
  if @cache[cache_key]
    puts "💾 Respuesta desde caché"
    return @cache[cache_key]
  end
  
  # ... proceso normal ...
  
  @cache[cache_key] = response
  response
end
```

### 5. **Rate Limiting en el backend**

Limitar peticiones por usuario:

```ruby
# En chat_controller.rb
@last_request = {}

def handle_message(app, request, params)
  user_id = extract_user_id(token)
  last_time = @last_request[user_id]
  
  if last_time && (Time.now - last_time) < 3
    app.halt 429, { 
      error: 'Por favor espera 3 segundos entre mensajes',
      retry_after: 3 
    }.to_json
  end
  
  @last_request[user_id] = Time.now
  # ... continuar normal ...
end
```

## 🔍 Verificar Estado Actual

### Ver cuota restante:
```bash
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash?key=TU_API_KEY"
```

### Monitorear uso:
https://ai.dev/rate-limit

## 💡 Mejora Implementada

Ahora cuando hay error 429, el usuario ve:

```
Lo siento, el servicio de IA está temporalmente sobrecargado debido al alto uso.

🕒 Por favor, intenta de nuevo en aproximadamente 51 segundos.

Si el problema persiste, el sistema puede estar en período de espera por límite de cuota gratuita.
```

En lugar de un error técnico.

## 🎯 Recomendación Inmediata

**Para desarrollo:**
1. Cambia el modelo a `gemini-1.5-flash`
2. Espera 1 minuto entre pruebas

**Para producción:**
1. Obtén API Key de pago
2. Implementa rate limiting
3. Usa caché para respuestas frecuentes

## 📝 Cambios Aplicados

✅ El sistema ahora maneja el error 429 graciosamente
✅ Muestra tiempo de espera al usuario
✅ No rompe la aplicación
✅ Mensaje amigable en lugar de error técnico

---

**Archivo modificado:** [llm/gemini_adapter.rb](d:\graphql_service\ai-gateway\llm\gemini_adapter.rb)
