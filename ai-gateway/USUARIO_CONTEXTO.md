# 👤 Información del Usuario en el Agente IA

## ✅ El Agente PUEDE Ver Información del Usuario

Sí, el agente del Pilar 3 puede identificar y usar información del usuario conectado.

## 📊 Información Disponible

### Del JWT Token
El agente extrae automáticamente del token JWT:

```ruby
{
  user_id: "123",           # ID único del usuario
  username: "Dr. Juan",     # Nombre del usuario
  email: "juan@example.com",# Email
  role: "medico",          # Rol (médico, paciente, farmaceutico, admin)
  exp: 1234567890          # Expiración del token
}
```

### Ubicación (si está disponible)
```ruby
{
  user_lat: -12.0464,      # Latitud
  user_lng: -77.0428       # Longitud
}
```

## 🎯 Cómo el Agente Usa Esta Información

### 1. Personalización del Prompt

El sistema personaliza automáticamente el prompt según el rol:

**Para Médicos:**
```
Estás hablando con: Dr. Juan
El usuario es un MÉDICO. Puede crear y consultar recetas médicas.
```

**Para Pacientes:**
```
Estás hablando con: María López
El usuario es un PACIENTE. Puede consultar recetas y buscar medicamentos.
```

**Para Farmacéuticos:**
```
Estás hablando con: Carlos Pérez
El usuario es un FARMACÉUTICO. Puede gestionar inventario y dispensar medicamentos.
```

### 2. Respuestas Personalizadas

El agente puede:

✅ **Saludar por nombre:**
```
Usuario: "Hola"
AI: "¡Hola Dr. Juan! ¿En qué puedo ayudarte hoy?"
```

✅ **Adaptar funcionalidades según rol:**
```
Usuario (médico): "Quiero crear una receta"
AI: "Perfecto Dr. Juan, puedo ayudarte a crear una receta. ¿Para qué paciente?"

Usuario (paciente): "Quiero crear una receta"
AI: "Lo siento María, solo los médicos pueden crear recetas. ¿Quieres consultar tus recetas existentes?"
```

✅ **Usar ubicación para farmacias:**
```
Usuario: "¿Dónde hay farmacias?"
AI: "Basándome en tu ubicación, encontré estas farmacias cerca:"
```

## 🔧 Estructura del Contexto

### En ChatController
```ruby
context = {
  user_id: "123",
  username: "Dr. Juan",
  role: "medico",
  user_lat: -12.0464,
  user_lng: -77.0428
}

agent = Agent.new(token: token, context: context)
```

### En ContextBuilder
```ruby
def system_prompt
  "Estás hablando con: #{@user_context[:username]}"
  "El usuario es un #{@user_context[:role]}"
end
```

### En Agent
```ruby
def process_message(message)
  context_data = @context.build(message)
  # context_data incluye toda la info del usuario
end
```

## 📝 Ejemplos de Uso

### Ejemplo 1: Verificar Rol antes de Crear Receta
```ruby
# En MCP::CrearReceta
def self.execute(params, token, context)
  role = context[:role]
  
  unless role == 'medico' || role == 'doctor'
    return {
      success: false,
      error: "Solo los médicos pueden crear recetas. Tu rol es: #{role}"
    }
  end
  
  # Crear receta...
end
```

### Ejemplo 2: Personalizar Búsqueda de Productos
```ruby
# En MCP::BuscarProducto
def self.execute(params, token, context)
  username = context[:username] || 'Usuario'
  productos = service.buscar(params[:nombre])
  
  {
    success: true,
    data: productos,
    message: "#{username}, encontré #{productos.size} productos"
  }
end
```

### Ejemplo 3: Filtrar por Rol
```ruby
# En Agent#detect_tools_needed
def detect_tools_needed(message)
  tools = []
  
  # Solo médicos pueden crear recetas
  if message.match?(/crear.*receta/i)
    if @user_context[:role] == 'medico'
      tools << 'crear_receta'
    else
      # Retornar error amigable
      tools << 'error_permiso'
    end
  end
  
  tools
end
```

## 🔐 Seguridad

### Validación de Token
```ruby
def extract_user_info(token)
  # Decodifica y valida JWT
  # Verifica expiración
  # Retorna info del usuario
end
```

### Niveles de Acceso

| Rol | Crear Recetas | Ver Recetas | Gestionar Stock | Ver Reportes |
|-----|--------------|-------------|-----------------|--------------|
| Médico | ✅ | ✅ | ❌ | ❌ |
| Paciente | ❌ | ✅ (propias) | ❌ | ❌ |
| Farmacéutico | ❌ | ✅ | ✅ | ✅ |
| Admin | ✅ | ✅ | ✅ | ✅ |

## 🎨 Interfaz de Usuario

### Frontend (chat.js)
El frontend envía automáticamente:
```javascript
{
  message: "hola",
  user_lat: -12.0464,
  user_lng: -77.0428
}
```

Con headers:
```javascript
headers: {
  'Authorization': `Bearer ${authToken}`
}
```

### Backend Extrae
```ruby
user_id = extract_user_id(token)        # "123"
user_info = extract_user_info(token)     # { username: "Dr. Juan", ... }
```

## 📊 Flujo Completo

```
1. Usuario envía mensaje
   ↓
2. Frontend envía con JWT token
   ↓
3. ChatController extrae info del token
   - user_id
   - username
   - role
   ↓
4. Crea Agent con contexto
   ↓
5. ContextBuilder personaliza prompt
   - "Hablando con: Dr. Juan"
   - "El usuario es médico"
   ↓
6. Agent procesa mensaje
   - Detecta herramientas según rol
   - Ejecuta con permisos
   ↓
7. LLM genera respuesta personalizada
   ↓
8. Usuario ve respuesta con su nombre
```

## 🧪 Probar

### Ver información del usuario en logs
```ruby
# En ChatController, verás:
👤 Usuario: 123 (Dr. Juan)
```

### Enviar mensaje personalizado
```
Usuario: "¿Quién soy?"
AI: "Eres Dr. Juan, un médico en el sistema SaluMedX."
```

## 💡 Mejoras Futuras

- [ ] Cache de información del usuario
- [ ] Historial por usuario
- [ ] Preferencias personalizadas
- [ ] Notificaciones específicas por rol
- [ ] Dashboard personalizado según rol
- [ ] Sugerencias inteligentes basadas en historial

---

**Resumen:** ✅ El agente SÍ puede ver quién es el usuario, su rol, ubicación y personalizar completamente las respuestas.
