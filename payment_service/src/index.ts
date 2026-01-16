import express, { Request, Response } from 'express';
import Stripe from 'stripe';
import axios from 'axios';
import { config } from './config';
import { StripeAdapter } from './adapters/StripeAdapter';
import { MockAdapter } from './adapters/MockAdapter'; // PILAR 2 - Mock Adapter
import { PaymentAdapter } from './adapters/PaymentAdapter'; // PILAR 2 - Mock Adapter
import { WebhookNormalizer } from './services/WebhookNormalizer'; // PILAR 2 - Webhook Normalization
import { PartnerManager } from './services/PartnerManager'; // PILAR 2 - Partner Registration

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

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'payment_service' });
});

app.listen(config.port, () => {
  console.log(`Payment service listening on port ${config.port}`);
});
