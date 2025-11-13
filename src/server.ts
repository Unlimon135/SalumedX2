import express from 'express';
import http from 'http';
import { NotificationService } from "./services/notification.service";
import { WebSocketServerService } from './services/websocket.service';
// Configuración de Express
const app = express();

// Servidor HTTP + WebSocket
const server = http.createServer(app);

//Inicializa el servidor WebSocket con el patrón Singleton
const wsServer = WebSocketServerService.getInstance(server);

// Endpoint de prueba (simula el servicio REST)
app.post('/api/notifications', express.json(), async (req, res) => {
  const {type,data} = req.body;
  NotificationService.getInstance().publish(type, data);
  res.status(200).json({ message: 'Notificación enviada UWU OKI' });
});


// Iniciar servidor
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`✅ Servidor escuchando en http://localhost:${PORT}`);
});
