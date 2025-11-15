import express from 'express';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import { NotificationService } from "./services/notification.service.js";
import { WebSocketServerService } from './services/websocket.service.js';

// Obtener __dirname en ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuración de Express
const app = express();

// Middleware para parsear JSON
app.use(express.json());

// Servidor HTTP + WebSocket
const server = http.createServer(app);

// Servir archivos estáticos desde la carpeta src
app.use(express.static(path.join(__dirname)));

//Inicializa el servidor WebSocket con el patrón Singleton
const wsServer = WebSocketServerService.getInstance(server);

// Endpoint para recibir notificaciones
app.post('/api/notifications', (req, res) => {
  try {
    const {type, data} = req.body;
    console.log(`📨 Notificación recibida: ${type}`, data);
    NotificationService.getInstance().publish(type, data);
    res.status(200).json({ message: 'Notificación enviada correctamente' });
  } catch (error) {
    console.error('❌ Error al procesar notificación:', error);
    res.status(500).json({ error: 'Error al procesar notificación' });
  }
});

// Health check endpoint
app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Servidor WebSocket activo' });
});

// Iniciar servidor
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`✅ Servidor escuchando en http://localhost:${PORT}`);
  console.log(`📊 WebSocket disponible en ws://localhost:${PORT}`);
});
