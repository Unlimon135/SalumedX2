import dotenv from 'dotenv';

dotenv.config();

type Config = {
  port: number;
  stripeSecretKey: string;
  stripeWebhookSecret: string;
  internalSecret: string;
  djangoConfirmationUrl: string;
  paymentProvider: 'stripe' | 'mock'; // PILAR 2 - Mock Adapter: Selector de proveedor
};

// PILAR 2 - Mock Adapter: Solo requerir variables de Stripe si el proveedor es 'stripe'
const paymentProvider = (process.env.PAYMENT_PROVIDER || 'stripe').toLowerCase();
const required = paymentProvider === 'stripe' 
  ? ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET', 'INTERNAL_SECRET'] as const
  : ['INTERNAL_SECRET'] as const;

required.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable ${key}`);
  }
});

export const config: Config = {
  port: Number(process.env.PORT || 4000),
  stripeSecretKey: process.env.STRIPE_SECRET_KEY || '', // PILAR 2 - Mock Adapter: Opcional si usa mock
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET || '', // PILAR 2 - Mock Adapter: Opcional si usa mock
  internalSecret: process.env.INTERNAL_SECRET as string,
  djangoConfirmationUrl: process.env.DJANGO_CONFIRM_URL || 'http://localhost:8000/api/pagos/confirmar/',
  paymentProvider: paymentProvider as 'stripe' | 'mock', // PILAR 2 - Mock Adapter
};
