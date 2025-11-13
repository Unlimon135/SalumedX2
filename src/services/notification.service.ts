// File: websocket_web2/src/services/notification.service.ts
// Definición del tipo Subscriber
type Subscriber =(event: string, data: any) => void;
// Servicio de notificaciones con patrón observer
export class NotificationService {
  private static instance: NotificationService;
  private subscribers: Subscriber[] = [];
  // Constructor privado para evitar instanciación externa
  private constructor() {}
// Método estático para obtener la instancia única
  static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    //retorna la instancia única
    return NotificationService.instance;
  }
  // Método para suscribirse a notificaciones
  subscribe(fn: Subscriber): void {
    this.subscribers.push(fn);
  }
// Método para publicar notificaciones
  publish(event: string, data: any): void {
    this.subscribers.forEach((fn) => fn(event, data));
  }
}