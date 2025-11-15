// Definición de la interfaz NotificationStrategy
export interface NotificationStrategy {
  send(data: any): void;
}