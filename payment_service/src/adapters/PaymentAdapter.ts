export interface PaymentResponse {
  clientSecret: string;
  paymentIntentId: string;
}

export interface PaymentAdapter {
  createPayment(amount: number, reference: string): Promise<PaymentResponse>;
}
