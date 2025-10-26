import express from 'express';
import http from 'http';
import dotenv from 'dotenv';
import { setupWebSocket } from './services/websocket.service.js';
import { getNotifications } from './services/notification.service.js';

dotenv.config();

const app = express();
app.use(express.json());

// Endpoint de prueba (simula el servicio REST)
app.get('/api/notifications', async (_req, res) => {
  const data = await getNotifications();
  res.json(data);
});

// Servidor HTTP + WebSocket
const server = http.createServer(app);
setupWebSocket(server);

// Iniciar servidor
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`✅ Servidor escuchando en http://localhost:${PORT}`);
});
