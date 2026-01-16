// PILAR 2 - Bidirectional Webhooks
// Servicio para disparar eventos a partners registrados

import axios from 'axios';
import { NormalizedWebhookEvent } from '../types/NormalizedEvent';
import { PartnerManager } from './PartnerManager';
import { HMACService } from './HMACService';

export class WebhookDispatcher {
  /**
   * PILAR 2 - Bidirectional Webhooks
   * Disparar un evento a todos los partners suscritos
   * @param event - Evento normalizado
   * @param maxRetries - Número máximo de reintentos
   */
  static async dispatchEvent(event: NormalizedWebhookEvent, maxRetries: number = 1): Promise<void> {
    try {
      // PILAR 2 - Bidirectional Webhooks: Obtener partners suscritos a este evento
      const subscribedPartners = PartnerManager.getPartnersForEvent(event.type);

      if (subscribedPartners.length === 0) {
        console.log(`[PILAR 2] No partners subscribed to event: ${event.type}`);
        return;
      }

      console.log(`[PILAR 2] Dispatching event '${event.type}' to ${subscribedPartners.length} partners`);

      // PILAR 2 - Bidirectional Webhooks: Enviar a cada partner
      const dispatchPromises = subscribedPartners.map((partner) =>
        this.sendWebhookToPartner(event, partner.id, partner.webhookUrl, partner.hmacSecret, maxRetries)
      );

      // Ejecutar todos los envíos en paralelo (no-blocking)
      await Promise.allSettled(dispatchPromises);
    } catch (error) {
      console.error('[PILAR 2] Error dispatching webhooks', error);
    }
  }

  /**
   * PILAR 2 - Bidirectional Webhooks
   * Enviar webhook a un partner específico
   * @param event - Evento a enviar
   * @param partnerId - ID del partner
   * @param webhookUrl - URL del webhook del partner
   * @param hmacSecret - Secret para firmar
   * @param maxRetries - Reintentos disponibles
   */
  private static async sendWebhookToPartner(
    event: NormalizedWebhookEvent,
    partnerId: string,
    webhookUrl: string,
    hmacSecret: string,
    maxRetries: number
  ): Promise<void> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // PILAR 2 - Bidirectional Webhooks: Preparar payload con partnerId
        const payload = {
          ...event,
          partnerId, // Incluir partnerId para que el partner sepa de dónde viene
        };

        // PILAR 2 - Bidirectional Webhooks: Generar firma HMAC
        const signature = HMACService.signPayload(payload, hmacSecret);

        console.log(
          `[PILAR 2] Sending webhook to partner ${partnerId} (attempt ${attempt}/${maxRetries}): ${webhookUrl}`
        );

        // PILAR 2 - Bidirectional Webhooks: Enviar webhook con firma
        const response = await axios.post(webhookUrl, payload, {
          headers: {
            'Content-Type': 'application/json',
            'X-Signature': signature,
            'X-Event-Type': event.type,
            'X-Source': 'SalumedX2-PaymentService',
          },
          timeout: 5000, // 5 segundos de timeout
        });

        console.log(`[PILAR 2] Webhook sent successfully to partner ${partnerId} (${response.status})`);
        return; // Éxito, salir de reintentos
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));

        if (attempt < maxRetries) {
          console.warn(
            `[PILAR 2] Webhook send failed for partner ${partnerId} (attempt ${attempt}): ${lastError.message}. Retrying...`
          );
          // Esperar 1 segundo antes de reintentar
          await new Promise((resolve) => setTimeout(resolve, 1000));
        } else {
          console.error(
            `[PILAR 2] Webhook send failed for partner ${partnerId} after ${maxRetries} attempts: ${lastError.message}`
          );
        }
      }
    }

    // Log final de fallo si todos los reintentos fallaron
    if (lastError) {
      console.error(`[PILAR 2] Webhook dispatch to partner ${partnerId} failed: ${lastError.message}`);
    }
  }

  /**
   * PILAR 2 - Bidirectional Webhooks
   * Disparar evento de prueba para testing
   * (Útil para demos sin depender de eventos reales)
   */
  static async dispatchTestEvent(eventType: string = 'payment.succeeded'): Promise<void> {
    const testEvent: NormalizedWebhookEvent = {
      type: eventType,
      reference: `TEST-${Date.now()}`,
      amount: 99.99,
      currency: 'USD',
      paymentIntentId: `test_pi_${Date.now()}`,
      status: 'succeeded',
      source: 'mock',
      timestamp: Date.now(),
      metadata: {
        isTestEvent: true,
        generatedAt: new Date().toISOString(),
      },
    };

    console.log(`[PILAR 2] Dispatching test event: ${eventType}`);
    await this.dispatchEvent(testEvent);
  }
}
