// PILAR 2 - Webhook Normalization
// Formato estándar para eventos de webhooks de cualquier proveedor

export interface NormalizedWebhookEvent {
  type: string;              // Tipo de evento: 'payment.succeeded', 'payment.failed', etc.
  reference: string;         // Referencia de la orden/transacción
  amount: number;            // Monto en formato decimal (ej: 25.50)
  currency: string;          // Moneda (USD, EUR, etc.)
  paymentIntentId: string;   // ID único del pago
  status: string;            // Estado: 'succeeded', 'failed', 'pending'
  source: 'stripe' | 'mock' | 'mercadopago'; // Proveedor de origen
  timestamp: number;         // Timestamp Unix del evento
  metadata?: Record<string, any>; // Metadata adicional del proveedor
}

export interface WebhookNormalizationResult {
  success: boolean;
  event?: NormalizedWebhookEvent;
  error?: string;
}
