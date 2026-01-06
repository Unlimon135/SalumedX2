# 🔗 Integración Frontend con Pilar 3 - AI Gateway

## 📋 Resumen
Este documento explica cómo el frontend de SaluMedX está integrado con el microservicio AI Gateway (Pilar 3).

---

## 🎯 Componentes de la Integración

### 1. **Botón de Acceso en Dashboard** (`app.html`)
```html
<a href="#" @click.prevent="openChat" class="nav-link" 
   style="background: linear-gradient(135deg, #a78bfa 0%, #06b6d4 100%); 
          color: white; text-align: center; margin-bottom: 8px;">
  <i class="bi bi-robot"></i> 🤖 Asistente IA (Pilar 3)
</a>
```

**Ubicación:** Barra lateral de navegación  
**Función:** Abre la interfaz del chat multimodal  
**Método:** `openChat()` en `app.js`

---

### 2. **Método de Navegación** (`app.js`)
```javascript
openChat() {
  // Verificar sesión activa
  if (!this.authToken || !this.username) {
    this.error = 'Debes iniciar sesión para acceder al chat';
    return;
  }

  // Preservar sesión en localStorage
  localStorage.setItem('authToken', this.authToken);
  localStorage.setItem('username', this.username);
  localStorage.setItem('API_URL', this.API_URL);

  // Navegar a la interfaz del chat
  window.location.href = 'chat.html';
}
```

**Características:**
- ✅ Valida autenticación JWT
- ✅ Preserva datos de sesión
- ✅ Navegación sin perder contexto

---

### 3. **Interfaz de Chat** (`chat.html`)
```html
<head>
  <!-- Vue 3 -->
  <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
  
  <!-- Axios -->
  <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
  
  <!-- Estilos -->
  <link rel="stylesheet" href="styles.css">
  <link rel="stylesheet" href="chat-styles.css">
  
  <!-- Auth JWT -->
  <script src="auth-jwt.js"></script>
</head>
```

**Estructura:**
- 📱 Header con info de usuario y controles
- 📊 Sidebar con MCP Tools y opciones
- 💬 Área de mensajes con burbujas
- ⌨️ Input multimodal (texto, imagen, PDF)

---

### 4. **Lógica de Chat** (`chat.js`)

#### 📡 Configuración de Conexión
```javascript
data() {
  return {
    // Config
    AI_GATEWAY_URL: 'http://localhost:5000',
    API_URL: localStorage.getItem('API_URL') || 'https://salumedx-rest.onrender.com',
    
    // User Data
    username: '',
    authToken: null,
    
    // Chat Data
    messages: [],
    messageInput: ''
  };
}
```

#### 🔐 Autenticación
```javascript
checkAuth() {
  const token = localStorage.getItem('authToken');
  const username = localStorage.getItem('username');

  if (!token || !username) {
    window.location.href = 'app.html';
    return;
  }

  this.authToken = token;
  this.username = username;
  this.loadHistory();
}
```

#### 💬 Envío de Mensajes
```javascript
async sendMessage() {
  const message = this.messageInput.trim();
  if (!message || this.loading) return;

  this.addMessage('user', message);
  this.messageInput = '';
  this.isTyping = true;

  try {
    const response = await axios.post(
      `${this.AI_GATEWAY_URL}/chat/message`,
      { message },
      {
        headers: {
          'Authorization': `Bearer ${this.authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const assistantMessage = {
      role: 'assistant',
      content: response.data.response,
      tools_used: response.data.tools_used || [],
      data: response.data.data || null,
      timestamp: Date.now()
    };

    this.messages.push(assistantMessage);
    this.scrollToBottom();
  } catch (err) {
    this.error = err.response?.data?.error || 'Error al comunicarse con el asistente';
  } finally {
    this.isTyping = false;
    this.loading = false;
  }
}
```

#### 📷 Procesamiento de Imágenes (OCR)
```javascript
async uploadImage(event) {
  const file = event.target.files[0];
  if (!file) return;

  this.loading = true;
  this.loadingMessage = 'Procesando imagen con OCR...';
  this.addMessage('user', `📷 Imagen subida: ${file.name}`);

  try {
    const formData = new FormData();
    formData.append('image', file);

    const response = await axios.post(
      `${this.AI_GATEWAY_URL}/chat/image`,
      formData,
      {
        headers: {
          'Authorization': `Bearer ${this.authToken}`,
          'Content-Type': 'multipart/form-data'
        }
      }
    );

    const assistantMessage = {
      role: 'assistant',
      content: response.data.response,
      tools_used: response.data.tools_used || [],
      data: response.data.data || null,
      timestamp: Date.now()
    };

    this.messages.push(assistantMessage);
    this.scrollToBottom();
  } catch (err) {
    this.error = err.response?.data?.error || 'Error al procesar la imagen';
  } finally {
    this.loading = false;
  }
}
```

#### 📄 Procesamiento de PDFs
```javascript
async uploadPDF(event) {
  const file = event.target.files[0];
  if (!file) return;

  this.loading = true;
  this.loadingMessage = 'Extrayendo texto del PDF...';
  this.addMessage('user', `📄 PDF subido: ${file.name}`);

  try {
    const formData = new FormData();
    formData.append('pdf', file);

    const response = await axios.post(
      `${this.AI_GATEWAY_URL}/chat/pdf`,
      formData,
      {
        headers: {
          'Authorization': `Bearer ${this.authToken}`,
          'Content-Type': 'multipart/form-data'
        }
      }
    );

    const assistantMessage = {
      role: 'assistant',
      content: response.data.response,
      tools_used: response.data.tools_used || [],
      data: response.data.data || null,
      timestamp: Date.now()
    };

    this.messages.push(assistantMessage);
    this.scrollToBottom();
  } catch (err) {
    this.error = err.response?.data?.error || 'Error al procesar el PDF';
  } finally {
    this.loading = false;
  }
}
```

#### 📜 Historial de Conversaciones
```javascript
async loadHistory() {
  try {
    const response = await axios.get(
      `${this.AI_GATEWAY_URL}/chat/history?limit=50`,
      {
        headers: {
          'Authorization': `Bearer ${this.authToken}`
        }
      }
    );

    this.messages = response.data.history.map(h => ({
      role: h.role,
      content: h.message,
      timestamp: h.created_at * 1000,
      showData: false
    }));

    this.scrollToBottom();
  } catch (err) {
    console.error('Error cargando historial:', err);
  }
}
```

---

## 🛠️ Endpoints del AI Gateway

### 1. **Mensaje de Texto**
```
POST http://localhost:5000/chat/message
Headers: 
  Authorization: Bearer {JWT_TOKEN}
  Content-Type: application/json
Body: 
  {
    "message": "Busca paracetamol"
  }
Response:
  {
    "response": "Encontré 3 productos...",
    "tools_used": ["buscar_producto"],
    "data": {...}
  }
```

### 2. **Imagen (OCR)**
```
POST http://localhost:5000/chat/image
Headers: 
  Authorization: Bearer {JWT_TOKEN}
  Content-Type: multipart/form-data
Body: 
  image: <file>
Response:
  {
    "response": "He extraído el siguiente texto...",
    "tools_used": [],
    "data": {"extracted_text": "..."}
  }
```

### 3. **PDF**
```
POST http://localhost:5000/chat/pdf
Headers: 
  Authorization: Bearer {JWT_TOKEN}
  Content-Type: multipart/form-data
Body: 
  pdf: <file>
Response:
  {
    "response": "He analizado el PDF...",
    "tools_used": [],
    "data": {"extracted_text": "..."}
  }
```

### 4. **Historial**
```
GET http://localhost:5000/chat/history?limit=50
Headers: 
  Authorization: Bearer {JWT_TOKEN}
Response:
  {
    "history": [
      {
        "id": 1,
        "user_id": "user123",
        "role": "user",
        "message": "Hola",
        "created_at": 1704240000
      }
    ]
  }
```

### 5. **Limpiar Historial**
```
DELETE http://localhost:5000/chat/history
Headers: 
  Authorization: Bearer {JWT_TOKEN}
Response:
  {
    "message": "Historial eliminado correctamente"
  }
```

### 6. **Estadísticas**
```
GET http://localhost:5000/chat/stats
Response:
  {
    "total_messages": 42,
    "unique_users": 5,
    "messages_by_role": {
      "user": 21,
      "assistant": 21
    }
  }
```

---

## 🎨 Estilos (`chat-styles.css`)

### Variables CSS
```css
:root {
  --primary: #a78bfa;
  --primary-2: #06b6d4;
  --bg: #ffffff;
  --text: #1f2937;
  --border: #e5e7eb;
  --muted: #6b7280;
  --shadow: rgba(0, 0, 0, 0.1);
}

[data-theme="dark"] {
  --bg: #1f2937;
  --text: #f9fafb;
  --border: #374151;
  --muted: #9ca3af;
  --shadow: rgba(0, 0, 0, 0.3);
}
```

### Componentes Principales
- `.chat-header` - Barra superior
- `.chat-sidebar` - Panel lateral con tools
- `.chat-main` - Área principal de mensajes
- `.message.user` - Burbujas del usuario
- `.message.assistant` - Burbujas de la IA
- `.message-input-container` - Input de texto
- `.tools-used` - Badges de herramientas usadas

---

## 🚀 Flujo de Uso

### Escenario 1: Mensaje de Texto Simple
```
1. Usuario escribe: "Busca paracetamol"
2. Frontend: POST /chat/message con JWT
3. AI Gateway: 
   - Agent detecta necesidad de buscar_producto
   - Ejecuta MCPRouter
   - LLM genera respuesta con contexto
4. Frontend: Muestra respuesta con badge "buscar_producto"
5. DB: Guarda conversación en SQLite
```

### Escenario 2: Subida de Imagen
```
1. Usuario sube imagen de receta médica
2. Frontend: POST /chat/image con FormData
3. AI Gateway:
   - FileParser extrae texto con Tesseract OCR
   - Agent detecta medicamentos en texto
   - Ejecuta buscar_producto automáticamente
4. Frontend: Muestra texto extraído + disponibilidad
5. DB: Guarda interacción
```

### Escenario 3: Análisis de PDF
```
1. Usuario sube PDF de orden médica
2. Frontend: POST /chat/pdf
3. AI Gateway:
   - PDF-Reader extrae contenido
   - Agent analiza y ejecuta tools necesarios
4. Frontend: Muestra análisis completo
5. DB: Guarda datos estructurados
```

---

## 🔐 Seguridad

### Autenticación JWT
- ✅ Token guardado en `localStorage`
- ✅ Enviado en header `Authorization: Bearer {token}`
- ✅ Validado en cada request al AI Gateway
- ✅ Extracción de `user_id` desde JWT

### CORS
```ruby
use Rack::Cors do
  allow do
    origins '*'
    resource '*', 
      headers: :any, 
      methods: [:get, :post, :options]
  end
end
```

---

## 🧪 Testing

### Probar Frontend
1. Iniciar AI Gateway:
```bash
cd ai-gateway
ruby app.rb
```

2. Abrir frontend:
```
http://localhost:3000/app.html
```

3. Iniciar sesión con credenciales válidas

4. Click en "🤖 Asistente IA (Pilar 3)"

5. Enviar mensaje de prueba:
   - "Busca ibuprofeno"
   - "Muéstrame las ventas"
   - Subir imagen con texto
   - Subir PDF

### Verificar Integración
```bash
# Ver logs del AI Gateway
# Terminal mostrará:
# - Requests recibidos
# - Tools ejecutados
# - Respuestas generadas
# - Errores si existen
```

---

## 📊 Monitoreo

### Estadísticas en Sidebar
- **Total de mensajes:** Contador general
- **Usuarios únicos:** Cantidad de usuarios diferentes
- **Actualizar:** Botón para refrescar datos

### Historial Persistente
- Guardado en SQLite: `ai-gateway/chat_history.db`
- Cargar con botón "Cargar Historial"
- Limpiar con botón "Limpiar Chat"

---

## 🐛 Troubleshooting

### Error: "openChat is not defined"
**Solución:** Ver [FIX_CACHE_ERROR.md](app/public/FIX_CACHE_ERROR.md)
- Forzar recarga: `Ctrl + Shift + R`
- Limpiar caché del navegador

### Error: "Network Error"
**Causa:** AI Gateway no está corriendo  
**Solución:**
```bash
cd ai-gateway
ruby app.rb
# Debe mostrar: Listening on http://0.0.0.0:5000
```

### Error: "Unauthorized"
**Causa:** Token JWT expirado o inválido  
**Solución:** Cerrar sesión y volver a iniciar sesión

### Sesión se cierra al navegar
**Causa:** Token no guardado en localStorage  
**Solución:** Ya implementado en `openChat()`

---

## ✅ Checklist de Integración

- [x] Botón "Asistente IA" en sidebar
- [x] Método `openChat()` en app.js
- [x] Preservación de sesión con localStorage
- [x] Interfaz chat.html completa
- [x] Lógica chat.js con Vue 3
- [x] Estilos chat-styles.css
- [x] Integración con 5 MCP Tools
- [x] Soporte multimodal (texto, imagen, PDF)
- [x] Historial persistente (SQLite)
- [x] Autenticación JWT
- [x] Manejo de errores
- [x] Loading states
- [x] Tema claro/oscuro
- [x] Responsive design

---

## 📚 Archivos Relacionados

```
app/public/
├── app.html              # Dashboard principal con botón Pilar 3
├── app.js                # Lógica principal + openChat()
├── chat.html             # Interfaz del chat
├── chat.js               # Lógica Vue del chat
├── chat-styles.css       # Estilos del chat
├── styles.css            # Estilos globales
└── auth-jwt.js           # Utilidades JWT

ai-gateway/
├── app.rb                # Servidor Sinatra
├── controllers/
│   └── chat_controller.rb
├── gateway/
│   ├── agent.rb          # Orquestador IA
│   ├── mcp_router.rb     # Ejecutor de tools
│   └── context_builder.rb
├── llm/
│   ├── llm_factory.rb
│   ├── llm_adapter.rb
│   └── gemini_adapter.rb
├── mcp/
│   ├── actions/
│   ├── queries/
│   └── reports/
├── infra/
│   ├── db.rb             # SQLite wrapper
│   └── http_client.rb
└── utils/
    ├── file_parser.rb    # OCR + PDF
    └── prompt_builder.rb
```

---

## 🎯 Próximos Pasos

1. ✅ **Integración completa** - HECHO
2. ⚙️ **Optimizar prompts** del Agent
3. 📊 **Dashboard de analytics** para uso del chat
4. 🔔 **Notificaciones** cuando IA detecta urgencias
5. 🌐 **Deploy** del AI Gateway en producción
6. 📱 **Version móvil** del chat

---

## 📞 Soporte

Si encuentras problemas con la integración:
1. Revisar [README.md](ai-gateway/README.md) del AI Gateway
2. Revisar [FIX_CACHE_ERROR.md](app/public/FIX_CACHE_ERROR.md)
3. Verificar logs en terminal del AI Gateway
4. Revisar consola del navegador (F12)

---

**✨ Desarrollado para SaluMedX - Pilar 3: MCP Chatbot Multimodal con IA**
