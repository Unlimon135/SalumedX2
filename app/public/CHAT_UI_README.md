# 🤖 Chat UI - Asistente IA (Pilar 3)

Interfaz de usuario completa para el chatbot multimodal con IA del Pilar 3.

## 📋 Archivos

- **chat.html** - Estructura HTML del chat
- **chat.js** - Lógica de Vue.js 3
- **chat-styles.css** - Estilos específicos del chat

## ✨ Características

### 🎨 Interfaz
- **Chat vertical moderno** con burbujas de mensajes
- **Sidebar colapsable** con herramientas y opciones
- **Tema claro/oscuro** persistente
- **Diseño responsive** para móviles y tablets
- **Animaciones suaves** para mejor UX

### 💬 Funcionalidades de Chat
- ✅ Envío de mensajes con Enter (Shift+Enter para nueva línea)
- ✅ Historial de conversaciones cargado automáticamente
- ✅ Indicador de escritura mientras la IA procesa
- ✅ Formato de mensajes con Markdown básico
- ✅ Visualización de herramientas MCP usadas
- ✅ Expandir/contraer datos JSON de respuestas

### 🛠️ MCP Tools Integrados
Los 5 tools MCP están disponibles y se activan automáticamente:

1. **buscar_producto** - Buscar medicamentos/productos
   - Ejemplo: "Busca paracetamol"
   
2. **ver_receta** - Consultar receta por ID
   - Ejemplo: "Muéstrame la receta 123"
   
3. **crear_receta** - Crear nueva receta médica
   - Ejemplo: "Crea una receta para Juan Pérez"
   
4. **actualizar_stock** - Actualizar inventario
   - Ejemplo: "Actualiza el stock del producto 5 a 100 unidades"
   
5. **resumen_ventas** - Generar reportes
   - Ejemplo: "Muéstrame las ventas del mes"

### 📤 Multimodal

#### 📷 Imágenes (OCR)
- Subir imágenes de recetas, etiquetas, documentos
- Procesamiento con Tesseract OCR
- Extracción automática de texto
- Análisis por IA

**Formatos soportados:** JPG, PNG, GIF, BMP, TIFF

#### 📄 PDFs
- Subir documentos PDF
- Extracción de texto completo
- Análisis de contenido por IA
- Identificación de datos relevantes

**Uso:**
1. Click en "Subir Imagen (OCR)" o "Subir PDF" en el sidebar
2. Seleccionar archivo
3. Esperar procesamiento
4. Ver análisis de la IA

### 📊 Estadísticas
- Total de mensajes en el sistema
- Usuarios únicos activos
- Actualización en tiempo real

## 🔧 Configuración

### Variables en chat.js

```javascript
AI_GATEWAY_URL: 'http://localhost:5000'  // URL del AI Gateway
API_URL: 'https://salumedx-rest.onrender.com'  // API REST principal
```

### Autenticación
El chat usa el mismo sistema de autenticación JWT que el resto de la aplicación:
- Token almacenado en `localStorage`
- Se envía en header `Authorization: Bearer <token>`
- Redirección automática a login si no hay token

## 🎯 Flujo de Uso

### 1. Acceso
```
Usuario → Login (app.html) → Dashboard → Click "🤖 Asistente IA" → Chat UI
```

### 2. Primera Conversación
```
Usuario escribe mensaje → 
  ↓
Chat enviado a AI Gateway (POST /chat/message) →
  ↓
Agent detecta MCP tools necesarios →
  ↓
Ejecuta tools (buscar_producto, etc.) →
  ↓
LLM genera respuesta con contexto →
  ↓
Respuesta mostrada al usuario →
  ↓
Mensaje guardado en SQLite
```

### 3. Cargar Historial
```
Usuario abre chat →
  ↓
Carga automática del historial (GET /chat/history) →
  ↓
Mensajes mostrados en orden cronológico
```

### 4. Multimodal
```
Usuario sube imagen/PDF →
  ↓
Archivo procesado (OCR/extracción) →
  ↓
Texto enviado a IA para análisis →
  ↓
Respuesta contextual generada
```

## 🎨 Personalización de Estilos

### Colores Principales (chat-styles.css)
```css
--primary: #a78bfa    /* Morado para botones principales */
--primary-2: #06b6d4  /* Cyan para asistente IA */
```

### Mensajes
```css
.message.user        /* Burbujas del usuario (azul) */
.message.assistant   /* Burbujas de la IA (morado) */
```

### Sidebar
```css
.chat-sidebar         /* Ancho: 320px */
.chat-sidebar.collapsed  /* Ancho colapsado: 60px */
```

## 📱 Responsive

### Breakpoints
- **Desktop:** > 768px - Sidebar fijo a la izquierda
- **Mobile:** ≤ 768px - Sidebar flotante con toggle

### Adaptaciones Móviles
- Mensajes más anchos (85% vs 70%)
- Usuario info compacta en header
- Input hints en columna
- Sidebar con transición suave

## 🔒 Seguridad

### Validaciones
- ✅ Token JWT requerido en todos los endpoints
- ✅ Validación de tipos de archivo (imágenes/PDFs)
- ✅ Sanitización de mensajes antes de renderizar
- ✅ Límite de tamaño de archivos
- ✅ CORS configurado en AI Gateway

### Privacidad
- Historial aislado por usuario (user_id del JWT)
- No se comparten conversaciones entre usuarios
- Opción de limpiar historial completo

## 🐛 Troubleshooting

### Error: "Cannot load file -- sqlite3"
```bash
cd ai-gateway
bundle install
```

### Error: "CORS policy"
Verificar configuración en `ai-gateway/app.rb`:
```ruby
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :options]
  end
end
```

### Error: "Authorization token required"
1. Verificar que estás logueado en `app.html`
2. Revisar que el token esté en localStorage
3. Verificar expiración del token

### Chat no carga mensajes
1. Verificar que AI Gateway esté corriendo en puerto 5000
2. Revisar consola del navegador (F12)
3. Probar endpoint manualmente:
```bash
curl -H "Authorization: Bearer <token>" http://localhost:5000/chat/history
```

### Imágenes/PDFs no se procesan
1. Verificar que Tesseract esté instalado (para OCR)
2. Verificar tamaño del archivo (< 10MB recomendado)
3. Revisar logs del AI Gateway

## 📈 Métricas y Analytics

El chat registra automáticamente:
- Cada mensaje enviado/recibido
- Herramientas MCP utilizadas
- Timestamp de interacciones
- Usuario asociado a cada conversación

Ver estadísticas en el sidebar o endpoint `/chat/stats`

## 🚀 Próximas Mejoras

- [ ] Búsqueda en historial de conversaciones
- [ ] Conversaciones múltiples (threads)
- [ ] Compartir conversaciones
- [ ] Exportar chat a PDF
- [ ] Voice input (grabación de voz)
- [ ] Sugerencias inteligentes basadas en contexto
- [ ] Integración con notificaciones push
- [ ] Modo offline con service workers

## 📚 Ejemplos de Uso

### Consultas Médicas
```
Usuario: "¿Qué medicamentos tienes para el dolor de cabeza?"
IA: [Ejecuta buscar_producto] "Tenemos paracetamol 500mg, ibuprofeno..."
```

### Gestión de Inventario
```
Usuario: "Actualiza el stock de paracetamol a 50 unidades"
IA: [Ejecuta actualizar_stock] "Stock actualizado exitosamente..."
```

### Reportes
```
Usuario: "Dame un resumen de las ventas de esta semana"
IA: [Ejecuta resumen_ventas] "Ventas totales: $X, productos más vendidos..."
```

### Análisis de Documentos
```
Usuario: [Sube imagen de receta médica]
IA: [OCR + análisis] "He detectado una receta con los siguientes medicamentos..."
```

## 📞 Soporte

Para problemas o preguntas:
1. Revisar logs del AI Gateway
2. Revisar consola del navegador (F12)
3. Verificar conectividad de servicios
4. Consultar README del AI Gateway

---

**Desarrollado para SaluMedX - Pilar 3: MCP Chatbot Multimodal con IA**
