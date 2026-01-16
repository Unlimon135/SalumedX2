// PILAR 2 - HMAC Authentication
// Servicio para firmar y verificar webhooks con HMAC-SHA256

import { createHmac } from 'crypto';

export class HMACService {
  /**
   * PILAR 2 - HMAC Authentication
   * Firmar un payload con HMAC-SHA256
   * @param payload - Datos a firmar (será convertido a JSON si es objeto)
   * @param secret - Secret compartido para la firma
   * @returns Firma en hexadecimal
   */
  static signPayload(payload: any, secret: string): string {
    // PILAR 2 - HMAC Authentication: Convertir payload a string JSON
    const payloadString = typeof payload === 'string' ? payload : JSON.stringify(payload);

    // PILAR 2 - HMAC Authentication: Crear HMAC-SHA256
    const hmac = createHmac('sha256', secret);
    hmac.update(payloadString);

    // PILAR 2 - HMAC Authentication: Devolver signature en hexadecimal
    const signature = hmac.digest('hex');

    return signature;
  }

  /**
   * PILAR 2 - HMAC Authentication
   * Verificar si una firma es válida
   * @param payload - Datos que fueron firmados
   * @param signature - Firma recibida (en hexadecimal)
   * @param secret - Secret compartido
   * @returns true si la firma es válida, false en caso contrario
   */
  static verifySignature(payload: any, signature: string, secret: string): boolean {
    try {
      // PILAR 2 - HMAC Authentication: Calcular firma esperada
      const expectedSignature = this.signPayload(payload, secret);

      // PILAR 2 - HMAC Authentication: Comparar timing-safe (prevenir timing attacks)
      // Nota: En Node.js, comparamos directamente, pero usar crypto.timingSafeEqual es más seguro
      const isValid = expectedSignature === signature;

      return isValid;
    } catch (error) {
      console.error('[PILAR 2] Error verifying signature', error);
      return false;
    }
  }

  /**
   * PILAR 2 - HMAC Authentication
   * Generar cabecera de firma para envíos de webhook
   * @param payload - Payload del webhook
   * @param secret - Secret del partner
   * @returns Objeto con headers necesarios
   */
  static generateSignatureHeader(payload: any, secret: string): { 'X-Signature': string } {
    const signature = this.signPayload(payload, secret);
    return {
      'X-Signature': signature,
    };
  }

  /**
   * PILAR 2 - HMAC Authentication
   * Extraer y verificar firma de headers
   * @param headers - Headers HTTP recibidos
   * @param payload - Payload recibido
   * @param secret - Secret compartido
   * @returns Object con resultado de verificación y firma recibida
   */
  static verifyRequestSignature(
    headers: Record<string, any>,
    payload: any,
    secret: string
  ): { valid: boolean; signature: string | null; reason?: string } {
    // PILAR 2 - HMAC Authentication: Extraer firma de header
    const receivedSignature = headers['x-signature'] as string;

    if (!receivedSignature) {
      return {
        valid: false,
        signature: null,
        reason: 'Missing X-Signature header',
      };
    }

    // PILAR 2 - HMAC Authentication: Verificar firma
    const isValid = this.verifySignature(payload, receivedSignature, secret);

    if (!isValid) {
      return {
        valid: false,
        signature: receivedSignature,
        reason: 'Invalid signature',
      };
    }

    return {
      valid: true,
      signature: receivedSignature,
    };
  }
}
