import { NotificationStrategy } from "./base.strategy";
// Estrategia concreta para notificaciones de cambio de precio
export class PriceChangeStrategy implements NotificationStrategy {
    send(data: any): void {
    console.log(`📉 Precio actualizado: ${JSON.stringify(data)}`);
    }
}
