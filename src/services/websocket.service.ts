import { Server } from 'http';  
import { WebSocketServer, WebSocket } from 'ws'; 
import { NotificationService} from './notification.service';
import { Logger } from '../utils/logger';
// Servicio WebSocket con patrón Singleton
export class WebSocketServerService {
  private static instance: WebSocketServerService;
  private wss: WebSocketServer;
// Constructor privado para evitar instanciación externa  
  private constructor(server: Server) {
    this.wss = new WebSocketServer({ server });
    this.wss.on('connection', (socket: WebSocket) => {
    // Manejo de eventos de conexión
    Logger.info('🟢 Cliente conectado');
    socket.on('message', (message) => {
      Logger.info(`Mensaje recibido: ${message}`);
      });
      // Manejo de desconexión
    socket.on('close', () => {
      Logger.info('🔴 Cliente desconectado');
      });

    });
    // Suscripción a notificaciones
    NotificationService.getInstance().subscribe((event, data) => {
      this.broadcast(event, data);
    });
  }
// Método estático para obtener la instancia única
  static getInstance(server: Server): WebSocketServerService {
    if (!WebSocketServerService.instance) {
      if (!server)  throw new Error("Debe pasar el servidor HTTP para inicializar WebSocket oki");
          WebSocketServerService.instance = new WebSocketServerService(server);
    }
    //retorna la instancia única
    return WebSocketServerService.instance;
  }
  // Método para enviar mensajes a todos los clientes conectados
  private broadcast(event: string, data: any): void{
    const payload = JSON.stringify({ event, data });
    this.wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) client.send(payload);
    });
  }
}


