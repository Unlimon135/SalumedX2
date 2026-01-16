// PILAR 2 - Mock Adapter
// Implementación simulada del PaymentAdapter para desarrollo sin necesidad de Stripe real

import { PaymentAdapter, PaymentResponse } from './PaymentAdapter';

export class MockAdapter implements PaymentAdapter {
  async createPayment(amount: number, reference: string): Promise<PaymentResponse> {
    // PILAR 2 - Mock Adapter: Simula la creación de un PaymentIntent sin llamar a Stripe
    
    // Validación básica
    if (amount <= 0) {
      throw new Error('Amount must be greater than zero');
    }

    if (!reference) {
      throw new Error('Reference is required');
    }

    // Simular delay de red (opcional, más realista)
    await new Promise(resolve => setTimeout(resolve, 100));

    // Generar IDs simulados
    const timestamp = Date.now();
    const mockPaymentIntentId = `mock_pi_${timestamp}_${reference.replace(/[^a-zA-Z0-9]/g, '')}`;
    const mockClientSecret = `mock_secret_${mockPaymentIntentId}_${Math.random().toString(36).substring(7)}`;

    console.log(`[MockAdapter] Payment created - Amount: $${amount}, Reference: ${reference}`);

    return {
      clientSecret: mockClientSecret,
      paymentIntentId: mockPaymentIntentId,
    };
  }
}
