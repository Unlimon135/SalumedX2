import Stripe from 'stripe';
import { PaymentAdapter, PaymentResponse } from './PaymentAdapter';

export class StripeAdapter implements PaymentAdapter {
  private stripe: Stripe;

  constructor(stripe: Stripe) {
    this.stripe = stripe;
  }

  async createPayment(amount: number, reference: string): Promise<PaymentResponse> {
    const amountInCents = Math.round(amount * 100);

    if (amountInCents <= 0) {
      throw new Error('Amount must be greater than zero');
    }

    const intent = await this.stripe.paymentIntents.create({
      amount: amountInCents,
      currency: 'usd',
      metadata: { reference },
      description: `Order reference ${reference}`,
      automatic_payment_methods: { enabled: true },
    });

    if (!intent.client_secret) {
      throw new Error('Stripe did not return a client secret');
    }

    return {
      clientSecret: intent.client_secret,
      paymentIntentId: intent.id,
    };
  }
}
