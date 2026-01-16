// PILAR 2 - Partner Registration
// Entidad Partner para almacenar información de grupos asociados

export interface Partner {
  id: string;                    // ID único del partner
  name: string;                  // Nombre del grupo/empresa partner
  webhookUrl: string;            // URL donde enviar webhooks
  eventosSuscritos: string[];    // Eventos que espera recibir: ['payment.succeeded', 'order.created', etc.]
  hmacSecret: string;            // Secret para firmar webhooks con HMAC
  createdAt: number;             // Timestamp de creación
  isActive: boolean;             // Si está activo para recibir webhooks
}
