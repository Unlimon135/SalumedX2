// PILAR 2 - Webhook Normalization
// Servicio que normaliza webhooks de diferentes proveedores a un formato común

import Stripe from 'stripe';
import { NormalizedWebhookEvent, WebhookNormalizationResult } from '../types/NormalizedEvent';

export class WebhookNormalizer {
  
  /**
   * PILAR 2 - Webhook Normalization
   * Normaliza un evento de Stripe a formato estándar
   */
  static normalizeStripeEvent(event: Stripe.Event): WebhookNormalizationResult {
    try {
      // Solo procesamos eventos de PaymentIntent
      if (event.type === 'payment_intent.succeeded') {
        const intent = event.data.object as Stripe.PaymentIntent;

        const normalized: NormalizedWebhookEvent = {
          type: 'payment.succeeded',
          reference: intent.metadata?.reference || 'N/A',
          amount: intent.amount_received / 100, // Convertir centavos a decimal
          currency: intent.currency.toUpperCase(),
          paymentIntentId: intent.id,
          status: 'succeeded',
          source: 'stripe',
          timestamp: event.created * 1000, // Convertir a milisegundos
          metadata: {
            stripeEventId: event.id,
            stripeEventType: event.type,
            paymentMethod: intent.payment_method,
            customer: intent.customer,
          }
        };

        return { success: true, event: normalized };
      }

      if (event.type === 'payment_intent.payment_failed') {
        const intent = event.data.object as Stripe.PaymentIntent;

        const normalized: NormalizedWebhookEvent = {
          type: 'payment.failed',
          reference: intent.metadata?.reference || 'N/A',
          amount: intent.amount / 100,
          currency: intent.currency.toUpperCase(),
          paymentIntentId: intent.id,
          status: 'failed',
          source: 'stripe',
          timestamp: event.created * 1000,
          metadata: {
            stripeEventId: event.id,
            stripeEventType: event.type,
            lastPaymentError: intent.last_payment_error,
          }
        };

        return { success: true, event: normalized };
      }

      // Evento no soportado
      return { 
        success: false, 
        error: `Stripe event type '${event.type}' not supported for normalization` 
      };

    } catch (error) {
      return {
        success: false,
        error: `Failed to normalize Stripe event: ${error instanceof Error ? error.message : 'Unknown error'}`
      };
    }
  }

  /**
   * PILAR 2 - Webhook Normalization
   * Normaliza un evento simulado de MockAdapter a formato estándar
   */
  static normalizeMockEvent(payload: any): WebhookNormalizationResult {
    try {
      // Validar estructura básica
      if (!payload.type || !payload.paymentIntentId) {
        return { success: false, error: 'Invalid mock event structure' };
      }

      const normalized: NormalizedWebhookEvent = {
        type: payload.type, // 'payment.succeeded', 'payment.failed', etc.
        reference: payload.reference || 'MOCK-REF',
        amount: payload.amount || 0,
        currency: payload.currency || 'USD',
        paymentIntentId: payload.paymentIntentId,
        status: payload.status || 'succeeded',
        source: 'mock',
        timestamp: payload.timestamp || Date.now(),
        metadata: payload.metadata || {}
      };

      return { success: true, event: normalized };

    } catch (error) {
      return {
        success: false,
        error: `Failed to normalize Mock event: ${error instanceof Error ? error.message : 'Unknown error'}`
      };
    }
  }

  /**
   * PILAR 2 - Webhook Normalization
   * Normaliza un evento de MercadoPago a formato estándar (preparado para futura implementación)
   */
  static normalizeMercadoPagoEvent(payload: any): WebhookNormalizationResult {
    // PILAR 2 - Webhook Normalization: Placeholder para MercadoPago
    return {
      success: false,
      error: 'MercadoPago normalization not implemented yet'
    };
  }

  /**
   * PILAR 2 - Webhook Normalization
   * Método genérico que detecta el proveedor y normaliza automáticamente
   */
  static normalizeEvent(source: 'stripe' | 'mock' | 'mercadopago', payload: any): WebhookNormalizationResult {
    switch (source) {
      case 'stripe':
        return this.normalizeStripeEvent(payload);
      case 'mock':
        return this.normalizeMockEvent(payload);
      case 'mercadopago':
        return this.normalizeMercadoPagoEvent(payload);
      default:
        return { success: false, error: `Unknown source: ${source}` };
    }
  }
}
