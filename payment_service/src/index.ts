import express, { Request, Response } from 'express';
import Stripe from 'stripe';
import axios from 'axios';
import { config } from './config';
import { StripeAdapter } from './adapters/StripeAdapter';
import { MockAdapter } from './adapters/MockAdapter'; // PILAR 2 - Mock Adapter
import { PaymentAdapter } from './adapters/PaymentAdapter'; // PILAR 2 - Mock Adapter
import { WebhookNormalizer } from './services/WebhookNormalizer'; // PILAR 2 - Webhook Normalization
import { PartnerManager } from './services/PartnerManager'; // PILAR 2 - Partner Registration
import { HMACService } from './services/HMACService'; // PILAR 2 - HMAC Authentication
import { WebhookDispatcher } from './services/WebhookDispatcher'; // PILAR 2 - Bidirectional Webhooks

const app = express();

// PILAR 2 - Mock Adapter: Seleccionar proveedor según configuración
let adapter: PaymentAdapter;
let stripe: Stripe | null = null;

if (config.paymentProvider === 'mock') {
  console.log('[PILAR 2] Using MockAdapter for development');
  adapter = new MockAdapter();
} else {
  console.log('[PILAR 2] Using StripeAdapter for production');
  stripe = new Stripe(config.stripeSecretKey, { apiVersion: '2023-10-16' });
  adapter = new StripeAdapter(stripe);
}

// Webhook needs raw body for signature validation
// PILAR 2 - Mock Adapter: Solo funciona con Stripe real
app.post('/webhooks/stripe', express.raw({ type: 'application/json' }), async (req: Request, res: Response) => {
  // PILAR 2 - Mock Adapter: Validar que se esté usando Stripe
  if (config.paymentProvider !== 'stripe' || !stripe) {
    return res.status(400).json({ error: 'Stripe webhooks not available in mock mode' });
  }

  const signature = req.headers['stripe-signature'];

  if (!signature) {
    return res.status(400).send('Missing stripe-signature header');
  }

  try {
    const event = stripe.webhooks.constructEvent(req.body, signature, config.stripeWebhookSecret);

    // PILAR 2 - Webhook Normalization: Normalizar evento de Stripe a formato estándar
    const normalizationResult = WebhookNormalizer.normalizeStripeEvent(event);

    if (!normalizationResult.success) {
      console.log(`[PILAR 2] Stripe event not normalized: ${normalizationResult.error}`);
      return res.json({ received: true, normalized: false });
    }

    const normalizedEvent = normalizationResult.event!;
    console.log(`[PILAR 2] Normalized event:`, {
      type: normalizedEvent.type,
      reference: normalizedEvent.reference,
      amount: normalizedEvent.amount,
      source: normalizedEvent.source
    });

    // PILAR 2 - Webhook Normalization: Procesar solo eventos de pago exitoso
    if (normalizedEvent.type === 'payment.succeeded') {
      // PILAR 2 - Bidirectional Webhooks: Disparar evento a partners suscritos
      WebhookDispatcher.dispatchEvent(normalizedEvent).catch((err) => {
        console.error('[PILAR 2] Error dispatching webhooks to partners', err);
      });

      // Notify Django backend for internal confirmation
      try {
        await axios.post(
          config.djangoConfirmationUrl,
          {
            reference: normalizedEvent.reference,
            paymentIntentId: normalizedEvent.paymentIntentId,
            amount: normalizedEvent.amount,
            currency: normalizedEvent.currency,
            status: normalizedEvent.status,
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'X-INTERNAL-SECRET': config.internalSecret,
            },
            timeout: 5000,
          }
        );
        console.log(`[PILAR 2] Django notified successfully for ${normalizedEvent.reference}`);
      } catch (postError) {
        console.error('Failed to notify Django backend', postError);
      }
    }

    return res.json({ received: true, normalized: true, eventType: normalizedEvent.type });
  } catch (err) {
    console.error('Webhook signature verification failed', err);
    return res.status(400).send('Webhook Error: signature verification failed');
  }
});

// Default JSON parser for other routes
app.use(express.json());

// PILAR 2 - Webhook Normalization: Endpoint para simular webhooks mock (solo en modo mock)
app.post('/webhooks/mock', async (req: Request, res: Response) => {
  if (config.paymentProvider !== 'mock') {
    return res.status(400).json({ error: 'Mock webhooks only available in mock mode' });
  }

  try {
    // PILAR 2 - Webhook Normalization: Normalizar evento mock
    const normalizationResult = WebhookNormalizer.normalizeMockEvent(req.body);

    if (!normalizationResult.success) {
      return res.status(400).json({ error: normalizationResult.error });
    }

    const normalizedEvent = normalizationResult.event!;
    console.log(`[PILAR 2] Mock webhook received and normalized:`, normalizedEvent);

    // PILAR 2 - Webhook Normalization: Procesar solo eventos de pago exitoso
    if (normalizedEvent.type === 'payment.succeeded') {
      // PILAR 2 - Bidirectional Webhooks: Disparar evento a partners suscritos
      WebhookDispatcher.dispatchEvent(normalizedEvent).catch((err) => {
        console.error('[PILAR 2] Error dispatching webhooks to partners', err);
      });

      try {
        await axios.post(
          config.djangoConfirmationUrl,
          {
            reference: normalizedEvent.reference,
            paymentIntentId: normalizedEvent.paymentIntentId,
            amount: normalizedEvent.amount,
            currency: normalizedEvent.currency,
            status: normalizedEvent.status,
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'X-INTERNAL-SECRET': config.internalSecret,
            },
            timeout: 5000,
          }
        );
        console.log(`[PILAR 2] Django notified from mock webhook`);
      } catch (postError) {
        console.error('Failed to notify Django backend from mock webhook', postError);
      }
    }

    return res.json({ received: true, normalized: true, event: normalizedEvent });
  } catch (err) {
    console.error('Mock webhook processing failed', err);
    return res.status(500).json({ error: 'Failed to process mock webhook' });
  }
});

app.post('/pay', async (req: Request, res: Response) => {
  const { amount, reference } = req.body as { amount?: number; reference?: string };

  if (typeof amount !== 'number' || amount <= 0 || !reference) {
    return res.status(400).json({ error: 'amount (number) and reference (string) are required' });
  }

  try {
    const payment = await adapter.createPayment(amount, reference);
    return res.json(payment);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error creating payment';
    console.error('Error creating payment', error);
    return res.status(500).json({ error: message });
  }
});

// PILAR 2 - Partner Registration: Endpoints para gestión de partners

/**
 * PILAR 2 - Partner Registration
 * POST /partners/register - Registrar un nuevo partner/grupo
 */
app.post('/partners/register', (req: Request, res: Response) => {
  const { name, webhookUrl, eventosSuscritos } = req.body as {
    name?: string;
    webhookUrl?: string;
    eventosSuscritos?: string[];
  };

  // PILAR 2 - Partner Registration: Validar entrada
  if (!name || !webhookUrl || !eventosSuscritos || !Array.isArray(eventosSuscritos)) {
    return res.status(400).json({
      error: 'name, webhookUrl, and eventosSuscritos (array) are required',
    });
  }

  if (eventosSuscritos.length === 0) {
    return res.status(400).json({
      error: 'eventosSuscritos cannot be empty',
    });
  }

  try {
    // PILAR 2 - Partner Registration: Registrar partner
    const partner = PartnerManager.registerPartner(name, webhookUrl, eventosSuscritos);

    return res.status(201).json({
      message: 'Partner registered successfully',
      partner: {
        id: partner.id,
        name: partner.name,
        webhookUrl: partner.webhookUrl,
        eventosSuscritos: partner.eventosSuscritos,
        hmacSecret: partner.hmacSecret,
        createdAt: partner.createdAt,
        isActive: partner.isActive,
      },
    });
  } catch (error) {
    console.error('Error registering partner', error);
    return res.status(500).json({ error: 'Failed to register partner' });
  }
});

/**
 * PILAR 2 - Partner Registration
 * GET /partners - Listar todos los partners registrados
 */
app.get('/partners', (_req: Request, res: Response) => {
  try {
    // PILAR 2 - Partner Registration: Obtener todos los partners
    const partners = PartnerManager.getAllPartners();

    return res.json({
      total: partners.length,
      partners: partners.map((p) => ({
        id: p.id,
        name: p.name,
        webhookUrl: p.webhookUrl,
        eventosSuscritos: p.eventosSuscritos,
        createdAt: p.createdAt,
        isActive: p.isActive,
        // NO incluir hmacSecret en la respuesta general por seguridad
      })),
    });
  } catch (error) {
    console.error('Error fetching partners', error);
    return res.status(500).json({ error: 'Failed to fetch partners' });
  }
});

/**
 * PILAR 2 - Partner Registration
 * DELETE /partners/:id - Eliminar un partner registrado
 */
app.delete('/partners/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    // PILAR 2 - Partner Registration: Eliminar partner
    const deleted = PartnerManager.deletePartner(id);

    if (!deleted) {
      return res.status(404).json({ error: 'Partner not found' });
    }

    return res.json({ message: 'Partner deleted successfully', partnerId: id });
  } catch (error) {
    console.error('Error deleting partner', error);
    return res.status(500).json({ error: 'Failed to delete partner' });
  }
});

// PILAR 2 - HMAC Authentication: Endpoint para recibir webhooks de partners

/**
 * PILAR 2 - HMAC Authentication
 * POST /webhooks/partner - Recibir webhooks de otros grupos/partners
 * Verifica la firma HMAC-SHA256 en el header X-Signature
 */
app.post('/webhooks/partner', (req: Request, res: Response) => {
  try {
    const { partnerId } = req.body as { partnerId?: string };

    // PILAR 2 - HMAC Authentication: Validar que se proporcione partnerId
    if (!partnerId) {
      return res.status(400).json({
        error: 'partnerId is required in request body',
      });
    }

    // PILAR 2 - HMAC Authentication: Obtener partner registrado
    const partner = PartnerManager.getPartnerById(partnerId);

    if (!partner) {
      console.warn(`[PILAR 2] Webhook received from unknown partner: ${partnerId}`);
      return res.status(404).json({
        error: 'Partner not found',
      });
    }

    if (!partner.isActive) {
      console.warn(`[PILAR 2] Webhook received from inactive partner: ${partnerId}`);
      return res.status(403).json({
        error: 'Partner is not active',
      });
    }

    // PILAR 2 - HMAC Authentication: Verificar firma HMAC
    const verificationResult = HMACService.verifyRequestSignature(
      req.headers,
      req.body,
      partner.hmacSecret
    );

    if (!verificationResult.valid) {
      console.warn(
        `[PILAR 2] Invalid HMAC signature from partner ${partnerId}: ${verificationResult.reason}`
      );
      return res.status(401).json({
        error: 'Invalid HMAC signature',
        reason: verificationResult.reason,
      });
    }

    console.log(`[PILAR 2] Valid webhook received from partner ${partnerId} (${partner.name})`);

    // PILAR 2 - HMAC Authentication: Validar estructura del evento
    const { type, reference, amount } = req.body as {
      type?: string;
      reference?: string;
      amount?: number;
    };

    if (!type) {
      return res.status(400).json({
        error: 'Event type is required',
      });
    }

    // PILAR 2 - HMAC Authentication: Verificar que el partner esté suscrito a este evento
    if (!partner.eventosSuscritos.includes(type)) {
      console.warn(
        `[PILAR 2] Partner ${partnerId} received unsubscribed event: ${type}`
      );
      return res.status(403).json({
        error: `Partner is not subscribed to event type: ${type}`,
      });
    }

    // PILAR 2 - HMAC Authentication: Log de evento procesado
    console.log(`[PILAR 2] Processing event from partner: type=${type}, reference=${reference}, amount=${amount}`);

    // PILAR 2 - HMAC Authentication: Aquí irían acciones de negocio
    // Por ahora solo registramos el evento recibido

    return res.json({
      message: 'Webhook received and verified successfully',
      partnerId: partnerId,
      partnerName: partner.name,
      eventType: type,
      signatureValid: true,
    });
  } catch (error) {
    console.error('[PILAR 2] Error processing partner webhook', error);
    return res.status(500).json({
      error: 'Failed to process webhook',
    });
  }
});

// PILAR 2 - HMAC Authentication: Endpoint de testing para generar firmas

/**
 * PILAR 2 - HMAC Authentication
 * POST /hmac/sign - Generar una firma HMAC para testing/debugging
 * (Solo para desarrollo, NO usar en producción)
 */
app.post('/hmac/sign', (req: Request, res: Response) => {
  const { payload, secret } = req.body as { payload?: any; secret?: string };

  if (!payload || !secret) {
    return res.status(400).json({
      error: 'payload and secret are required',
    });
  }

  try {
    // PILAR 2 - HMAC Authentication: Generar firma
    const signature = HMACService.signPayload(payload, secret);

    return res.json({
      payload,
      secret: '***', // NO devolver el secret completo
      signature,
      header: {
        'X-Signature': signature,
      },
      info: 'Use this signature in X-Signature header when sending webhooks',
    });
  } catch (error) {
    console.error('[PILAR 2] Error generating signature', error);
    return res.status(500).json({
      error: 'Failed to generate signature',
    });
  }
});

/**
 * PILAR 2 - HMAC Authentication
 * POST /hmac/verify - Verificar una firma HMAC para testing/debugging
 */
app.post('/hmac/verify', (req: Request, res: Response) => {
  const { payload, signature, secret } = req.body as {
    payload?: any;
    signature?: string;
    secret?: string;
  };

  if (!payload || !signature || !secret) {
    return res.status(400).json({
      error: 'payload, signature, and secret are required',
    });
  }

  try {
    // PILAR 2 - HMAC Authentication: Verificar firma
    const isValid = HMACService.verifySignature(payload, signature, secret);

    return res.json({
      valid: isValid,
      message: isValid ? 'Signature is valid' : 'Signature is invalid',
    });
  } catch (error) {
    console.error('[PILAR 2] Error verifying signature', error);
    return res.status(500).json({
      error: 'Failed to verify signature',
    });
  }
});

// PILAR 2 - Bidirectional Webhooks: Endpoint para testing y demostración

/**
 * PILAR 2 - Bidirectional Webhooks
 * POST /webhooks/test/trigger - Disparar evento de prueba a partners
 * Útil para testing sin depender de eventos reales
 */
app.post('/webhooks/test/trigger', async (req: Request, res: Response) => {
  const { eventType } = req.body as { eventType?: string };

  try {
    const type = eventType || 'payment.succeeded';

    console.log(`[PILAR 2] Test trigger for event: ${type}`);

    // PILAR 2 - Bidirectional Webhooks: Disparar evento de prueba
    await WebhookDispatcher.dispatchTestEvent(type);

    return res.json({
      message: 'Test event triggered',
      eventType: type,
      status: 'dispatching',
    });
  } catch (error) {
    console.error('[PILAR 2] Error triggering test event', error);
    return res.status(500).json({
      error: 'Failed to trigger test event',
    });
  }
});

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'payment_service' });
});

app.listen(config.port, () => {
  console.log(`Payment service listening on port ${config.port}`);
});
