// File: websocket_web2/src/models/notification.model.ts
// Definición de la interfaz Notification
export interface Notification {
  id?: number;
  type: "precio" | "promocion" | "alerta";
  message: string;
  timestamp?: Date;
  data?: any;
}
