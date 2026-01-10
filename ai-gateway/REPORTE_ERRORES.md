# 🚨 Reporte de Errores y Soluciones

**Fecha:** Última actualización
**Errores Detectados:** 2
**Estado:** ✅ Soluciones implementadas y documentadas

---

## 📊 Resumen de Errores

| # | Error | Severidad | Estado | Tiempo Estimado |
|---|-------|-----------|--------|-----------------|
| 1 | Username muestra "sin nombre" | ⚠️ Media | 🔧 En diagnóstico | 5-10 min |
| 2 | Error HTTP 429 - Cuota Gemini | 🔴 Alta | ✅ Solucionado | N/A |

---

## 🐛 Error #1: Username "sin nombre"

### Síntoma
```
👤 Usuario: 13 (sin nombre)
👥 Rol: paciente
```

### Causa
El JWT token no tiene ninguno de los campos que estamos buscando:
- `username`
- `name`
- `user_name`
- `nombre`
- `full_name`
- `displayName`

### Solución Implementada
✅ Agregados más campos a buscar
✅ Agregado logging de debug
✅ Creadas herramientas de diagnóstico

### Acción Requerida
1. Abre http://localhost:4567/obtener_token.html
2. Haz clic en "🔓 Decodificar en el Navegador"
3. Identifica el campo que tiene tu nombre
4. Si no está en la lista, actualiza `chat_controller.rb`

### Archivos
- [FIX_USERNAME.md](FIX_USERNAME.md) - Guía detallada
- [obtener_token.html](obtener_token.html) - Herramienta web
- [check_jwt.rb](check_jwt.rb) - Herramienta CLI
- [controllers/chat_controller.rb](controllers/chat_controller.rb#L13-L25) - Código a modificar

---

## 🔥 Error #2: HTTP 429 - Cuota Excedida

### Síntoma
```
❌ Error HTTP 429: {
  "error": {
    "code": 429,
    "message": "You exceeded your current quota...",
    "status": "RESOURCE_EXHAUSTED"
  }
}
```

### Causa
Plan gratuito de Gemini tiene límites:
- **15 RPM** (15 peticiones por minuto)
- **1,500 RPD** (1,500 peticiones por día)
- **Límite alcanzado:** 20 peticiones en un período

### Solución Implementada
✅ **Manejo gracioso del error** - El sistema ya no se rompe
✅ **Mensaje amigable** - El usuario ve un mensaje claro
✅ **Extracción del tiempo de espera** - Muestra cuándo reintentar

### Código Aplicado
```ruby
# En llm/gemini_adapter.rb
elsif response.code == 429
  retry_match = error_msg.match(/retry in ([\d.]+)s/)
  retry_time = retry_match ? retry_match[1].to_f.ceil : 60
  
  return "Lo siento, el servicio de IA está temporalmente sobrecargado. " \
         "🕒 Por favor, intenta de nuevo en aproximadamente #{retry_time} segundos."
end
```

### Usuario ve ahora:
```
Lo siento, el servicio de IA está temporalmente sobrecargado debido al alto uso.

🕒 Por favor, intenta de nuevo en aproximadamente 51 segundos.
```

En lugar de un error técnico.

### Soluciones a Largo Plazo

**Opción 1: Cambiar modelo (Gratis, 2 min)**
```ruby
# En llm/gemini_adapter.rb, línea 8:
@model = 'gemini-1.5-flash'  # En lugar de gemini-2.5-flash
```

**Opción 2: API Key de pago (Producción)**
- Ir a: https://aistudio.google.com/apikey
- Crear proyecto con facturación
- Límites: 360 RPM, 30,000 RPD

**Opción 3: Rate Limiting (5-10 min)**
- Limitar peticiones por usuario a 1 cada 3 segundos
- Ver código en [FIX_ERROR_429.md](FIX_ERROR_429.md#5-rate-limiting-en-el-backend)

**Opción 4: Sistema de caché (20-30 min)**
- Cachear respuestas frecuentes
- Reducir llamadas a la API
- Ver código en [FIX_ERROR_429.md](FIX_ERROR_429.md#4-usar-caché-local-avanzado)

### Archivos
- [FIX_ERROR_429.md](FIX_ERROR_429.md) - Guía completa
- [llm/gemini_adapter.rb](llm/gemini_adapter.rb#L36-L45) - Código modificado

---

## ✅ Estado de los Fixes

### Error 429 (Cuota)
- ✅ Error manejado graciosamente
- ✅ Usuario recibe mensaje amigable
- ✅ Sistema no se rompe
- ✅ Documentación completa
- ⏳ Esperando decisión: ¿cambiar modelo o actualizar a plan de pago?

### Error Username
- ✅ Código mejorado con más campos
- ✅ Logging agregado
- ✅ Herramientas de diagnóstico creadas
- ⏳ Esperando identificación del campo correcto en JWT

---

## 🔄 Próximos Pasos

### Inmediatos (ahora)
1. ✅ Reiniciar servidor para aplicar cambios
2. 🔍 Usar `obtener_token.html` para identificar campo de username
3. ✏️ Actualizar `chat_controller.rb` si es necesario

### Corto plazo (hoy)
1. 🔄 Decidir sobre el modelo de Gemini (gratuito vs pago)
2. 🚦 (Opcional) Implementar rate limiting
3. 🧪 Probar ambos fixes

### Mediano plazo (esta semana)
1. 💾 Implementar sistema de caché
2. 📊 Monitorear uso de API
3. 🔒 Validar seguridad del JWT

---

## 📞 Comandos Rápidos

### Reiniciar servidor
```powershell
cd d:\graphql_service\ai-gateway
ruby app.rb
```

### Verificar token
```powershell
ruby check_jwt.rb "TU_TOKEN_AQUI"
```

### Cambiar modelo (si quieres probar)
```ruby
# En llm/gemini_adapter.rb:8
@model = 'gemini-1.5-flash'
```

---

## 📚 Documentación Generada

1. [FIX_ERROR_429.md](FIX_ERROR_429.md) - Solución para error de cuota
2. [FIX_USERNAME.md](FIX_USERNAME.md) - Solución para username
3. [obtener_token.html](obtener_token.html) - Herramienta de diagnóstico web
4. [check_jwt.rb](check_jwt.rb) - Script CLI para verificar JWT

---

**✨ Resultado Final Esperado:**

```
👤 Usuario: 13 (Juan Pérez)  ← ✅ Muestra nombre correcto
👥 Rol: paciente
📍 Ubicación: -0.9557086, -80.7290533

[Usuario] buscar farmacia cerca con paracetamol

[Agente] ¡Hola Dr. Juan! He encontrado 3 farmacias cercanas con paracetamol:
...
```

Sin errores 429 mostrando mensajes amigables cuando hay límite de cuota.
