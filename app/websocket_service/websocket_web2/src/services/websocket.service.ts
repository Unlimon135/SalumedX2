import { Server } from 'http';  
import { WebSocketServer, WebSocket } from 'ws'; 
import { NotificationService} from './notification.service.js';
import { Logger } from '../utils/logger.js';

// Servicio WebSocket con patrón Singleton
export class WebSocketServerService {
  private static instance: WebSocketServerService;
  private wss: WebSocketServer;

// Constructor privado para evitar instanciación externa  
  private constructor(server: Server) {
    this.wss = new WebSocketServer({ server });
    Logger.info('🚀 WebSocketServer inicializado');
    
    this.wss.on('connection', (socket: WebSocket) => {
      // Manejo de eventos de conexión
      Logger.info('🟢 Cliente conectado. Total clientes: ' + this.wss.clients.size);
      
      socket.on('message', (message) => {
        Logger.info(`Mensaje recibido del cliente: ${message}`);
      });
      
      // Manejo de desconexión
      socket.on('close', () => {
        Logger.info('🔴 Cliente desconectado. Total clientes: ' + this.wss.clients.size);
      });

      socket.on('error', (error) => {
        Logger.error(`Error en socket: ${error.message}`);
      });
    });

    // Suscripción a notificaciones del servicio
    NotificationService.getInstance().subscribe((event, data) => {
      Logger.info(`📤 Broadcasting evento: ${event} a ${this.wss.clients.size} clientes`);
      this.broadcast(event, data);
    });
  }

// Método estático para obtener la instancia única
  static getInstance(server: Server): WebSocketServerService {
    if (!WebSocketServerService.instance) {
      if (!server) throw new Error("Debe pasar el servidor HTTP para inicializar WebSocket");
      WebSocketServerService.instance = new WebSocketServerService(server);
    }
    return WebSocketServerService.instance;
  }

  // Método para enviar mensajes a todos los clientes conectados
  private broadcast(event: string, data: any): void {
    const payload = JSON.stringify({ event, data });
    let sentCount = 0;
    
    this.wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(payload);
        sentCount++;
      }
    });
    
    Logger.info(`✅ Evento '${event}' enviado a ${sentCount} clientes`);
  }
}


