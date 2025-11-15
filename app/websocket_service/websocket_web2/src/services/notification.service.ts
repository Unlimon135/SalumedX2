import { Logger } from '../utils/logger.js';

// Definición del tipo Subscriber
type Subscriber = (event: string, data: any) => void;

// Servicio de notificaciones con patrón observer
export class NotificationService {
  private static instance: NotificationService;
  private subscribers: Subscriber[] = [];

  // Constructor privado para evitar instanciación externa
  private constructor() {
    Logger.info('🔔 NotificationService inicializado');
  }

  // Método estático para obtener la instancia única
  static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  // Método para suscribirse a notificaciones
  subscribe(fn: Subscriber): void {
    this.subscribers.push(fn);
    Logger.info(`✅ Nueva suscripción registrada. Total: ${this.subscribers.length}`);
  }

  // Método para publicar notificaciones
  publish(event: string, data: any): void {
    Logger.info(`📢 Publicando evento: ${event} a ${this.subscribers.length} subscribers`);
    this.subscribers.forEach((fn) => {
      try {
        fn(event, data);
      } catch (error) {
        Logger.error(`Error en subscriber: ${error}`);
      }
    });
  }
}