import dotenv from 'dotenv';

dotenv.config();

type Config = {
  port: number;
  stripeSecretKey: string;
  stripeWebhookSecret: string;
  internalSecret: string;
  djangoConfirmationUrl: string;
};

const required = ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET', 'INTERNAL_SECRET'] as const;

required.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable ${key}`);
  }
});

export const config: Config = {
  port: Number(process.env.PORT || 4000),
  stripeSecretKey: process.env.STRIPE_SECRET_KEY as string,
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET as string,
  internalSecret: process.env.INTERNAL_SECRET as string,
  djangoConfirmationUrl: process.env.DJANGO_CONFIRM_URL || 'http://localhost:8000/api/pagos/confirmar/',
};
