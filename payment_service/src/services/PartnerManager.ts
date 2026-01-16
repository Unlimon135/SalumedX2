// PILAR 2 - Partner Registration
// Servicio para gestionar partners en memoria

import { randomBytes } from 'crypto';
import { Partner } from '../types/Partner';

export class PartnerManager {
  // PILAR 2 - Partner Registration: Storage en memoria
  private static partners: Map<string, Partner> = new Map();

  /**
   * PILAR 2 - Partner Registration
   * Registrar un nuevo partner
   */
  static registerPartner(
    name: string,
    webhookUrl: string,
    eventosSuscritos: string[]
  ): Partner {
    // PILAR 2 - Partner Registration: Generar ID único
    const partnerId = `partner_${Date.now()}_${Math.random().toString(36).substring(7)}`;

    // PILAR 2 - Partner Registration: Generar HMAC secret automáticamente
    const hmacSecret = randomBytes(32).toString('hex');

    const partner: Partner = {
      id: partnerId,
      name,
      webhookUrl,
      eventosSuscritos,
      hmacSecret,
      createdAt: Date.now(),
      isActive: true,
    };

    // Guardar en memoria
    this.partners.set(partnerId, partner);

    console.log(`[PILAR 2] Partner registered: ${name} (${partnerId})`);

    return partner;
  }

  /**
   * PILAR 2 - Partner Registration
   * Obtener todos los partners
   */
  static getAllPartners(): Partner[] {
    return Array.from(this.partners.values());
  }

  /**
   * PILAR 2 - Partner Registration
   * Obtener un partner por ID
   */
  static getPartnerById(partnerId: string): Partner | undefined {
    return this.partners.get(partnerId);
  }

  /**
   * PILAR 2 - Partner Registration
   * Eliminar un partner
   */
  static deletePartner(partnerId: string): boolean {
    const result = this.partners.delete(partnerId);
    if (result) {
      console.log(`[PILAR 2] Partner deleted: ${partnerId}`);
    }
    return result;
  }

  /**
   * PILAR 2 - Partner Registration
   * Obtener partners activos suscritos a un evento específico
   */
  static getPartnersForEvent(eventType: string): Partner[] {
    return Array.from(this.partners.values()).filter(
      (partner) => partner.isActive && partner.eventosSuscritos.includes(eventType)
    );
  }

  /**
   * PILAR 2 - Partner Registration
   * Activar/desactivar un partner
   */
  static togglePartnerStatus(partnerId: string, isActive: boolean): Partner | undefined {
    const partner = this.partners.get(partnerId);
    if (partner) {
      partner.isActive = isActive;
      console.log(`[PILAR 2] Partner ${partnerId} status changed to ${isActive}`);
    }
    return partner;
  }
}
