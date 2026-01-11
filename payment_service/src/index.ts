import express, { Request, Response } from 'express';
import Stripe from 'stripe';
import axios from 'axios';
import { config } from './config';
import { StripeAdapter } from './adapters/StripeAdapter';

const app = express();
const stripe = new Stripe(config.stripeSecretKey, { apiVersion: '2023-10-16' });
const adapter = new StripeAdapter(stripe);

// Webhook needs raw body for signature validation
app.post('/webhooks/stripe', express.raw({ type: 'application/json' }), async (req: Request, res: Response) => {
  const signature = req.headers['stripe-signature'];

  if (!signature) {
    return res.status(400).send('Missing stripe-signature header');
  }

  try {
    const event = stripe.webhooks.constructEvent(req.body, signature, config.stripeWebhookSecret);

    if (event.type === 'payment_intent.succeeded') {
      const intent = event.data.object as Stripe.PaymentIntent;

      // Notify Django backend for internal confirmation
      try {
        await axios.post(
          config.djangoConfirmationUrl,
          {
            reference: intent.metadata?.reference,
            paymentIntentId: intent.id,
            amount: intent.amount_received / 100,
            currency: intent.currency,
            status: intent.status,
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'X-INTERNAL-SECRET': config.internalSecret,
            },
            timeout: 5000,
          }
        );
      } catch (postError) {
        console.error('Failed to notify Django backend', postError);
      }
    }

    return res.json({ received: true });
  } catch (err) {
    console.error('Webhook signature verification failed', err);
    return res.status(400).send('Webhook Error: signature verification failed');
  }
});

// Default JSON parser for other routes
app.use(express.json());

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

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'payment_service' });
});

app.listen(config.port, () => {
  console.log(`Payment service listening on port ${config.port}`);
});
