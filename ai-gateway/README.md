# 🤖 AI Gateway - Pilar 3: Chatbot Multimodal con MCP

Microservicio de inteligencia artificial conversacional para SaluMedX.

## 🏗️ Arquitectura

- **Framework:** Ruby + Sinatra
- **LLM Provider:** Google Gemini (configurable a OpenAI)
- **Pattern:** Strategy para LLM Adapters
- **MCP Tools:** 5 herramientas integradas con GraphQL/REST

## 📦 Instalación

```bash
cd ai-gateway
bundle install
```

## ⚙️ Configuración

Editar `.env`:

```env
# API Key de Gemini (obligatorio)
GEMINI_API_KEY=tu_api_key_aqui

# Provider (gemini u openai)
LLM_PROVIDER=gemini

# URLs de servicios
GRAPHQL_SERVICE_URL=http://localhost:4000/graphql
REST_API_URL=https://salumedx-rest.onrender.com
```

### Obtener API Key de Gemini:
1. Ir a https://makersuite.google.com/app/apikey
2. Crear un nuevo proyecto
3. Generar API Key
4. Copiar en el `.env`

## 🚀 Ejecutar

```bash
ruby app.rb
```

El servicio estará disponible en: `http://localhost:5000`

## �️ Frontend - Chat UI

El proyecto incluye una interfaz de chat completa y moderna:

**Ubicación:** `../app/public/chat.html`

**Características:**
- 💬 Chat vertical con historial persistente
- 🎨 Tema claro/oscuro
- 🤖 5 MCP Tools integrados
- 📷 Carga de imágenes con OCR
- 📄 Procesamiento de PDFs
- 📊 Estadísticas en tiempo real
- 📱 Diseño responsive

**Acceso:**
1. Iniciar sesión en `app.html`
2. Clic en el botón "🤖 Asistente IA (Pilar 3)"
3. O acceder directamente a `http://localhost:3000/chat.html`

## �📡 Endpoints

### Chat con texto
```bash
POST http://localhost:5000/chat/message
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "message": "Busca paracetamol"
}
```

### Chat con imagen (OCR)
```bash
POST http://localhost:5000/chat/image
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data

image: <archivo_imagen>
```

### Chat con PDF
```bash
POST http://localhost:5000/chat/pdf
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data

pdf: <archivo_pdf>
```

### Health check
```bash
GET http://localhost:5000/health
```

### Historial de conversaciones
```bash
# Obtener historial (últimos 20 mensajes)
GET http://localhost:5000/chat/history
Authorization: Bearer <jwt_token>

# Obtener historial con límite personalizado
GET http://localhost:5000/chat/history?limit=50
Authorization: Bearer <jwt_token>

# Limpiar historial del usuario
DELETE http://localhost:5000/chat/history
Authorization: Bearer <jwt_token>
```

### Estadísticas de la base de datos
```bash
GET http://localhost:5000/chat/stats
```

## 🔧 MCP Tools Disponibles

### Consultas (Queries)
1. **buscar_producto** - Busca productos/medicamentos
2. **ver_receta** - Consulta una receta por ID

### Acciones (Actions)
3. **crear_receta** - Crea una nueva receta médica
4. **actualizar_stock** - Actualiza inventario

### Reportes (Reports)
5. **resumen_ventas** - Genera reporte de ventas

## 🧪 Pruebas

### Probar con curl:

```bash
# Chat simple
curl -X POST http://localhost:5000/chat/message \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"message":"¿Qué productos tienes disponibles?"}'

# Con herramienta MCP
curl -X POST http://localhost:5000/chat/message \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"message":"Busca paracetamol"}'
```

## 📊 Flujo de Ejecución

```
Usuario → Chat Message
    ↓
ChatController
    ↓
Agent → Detecta herramientas necesarias
    ↓
MCPRouter → Ejecuta herramientas
    ↓
ProductService → Llama GraphQL
    ↓
LLM (Gemini) → Genera respuesta con contexto
    ↓
Respuesta al usuario
```

## 🎯 Características

- ✅ Procesamiento de texto en lenguaje natural
- ✅ OCR de imágenes con Tesseract
- ✅ Extracción de texto de PDFs
- ✅ 5 MCP Tools integrados
- ✅ Strategy Pattern para LLM Providers
- ✅ Contexto conversacional
- ✅ Autenticación JWT
- ✅ Integración con GraphQL Service
- ✅ **Historial de conversaciones con SQLite**
- ✅ **Persistencia de mensajes por usuario**
- ✅ **Estadísticas de uso**

## 💾 Base de Datos

El servicio utiliza **SQLite** para almacenar el historial de conversaciones:

- 📁 **Ubicación:** `chat_history.db` (creado automáticamente)
- 📊 **Tabla:** `messages` (id, user_id, message, role, created_at)
- 🔐 **Aislamiento:** Cada usuario ve solo su historial
- 🗑️ **Limpieza:** Endpoint para borrar historial por usuario

### Esquema de la base de datos

```sql
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  message TEXT NOT NULL,
  role TEXT DEFAULT 'user',      -- 'user' o 'assistant'
  created_at INTEGER NOT NULL    -- Unix timestamp
);
```

## 📝 Notas

- Requiere Tesseract instalado para OCR: `brew install tesseract` (Mac) o `apt-get install tesseract-ocr` (Linux)
- API de Gemini tiene límites gratuitos, monitorear uso
- Los MCP Tools requieren que el GraphQL Service esté corriendo
