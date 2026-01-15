# Pilar 2 – Sistema de Pagos y Webhooks (Stripe)

## Objetivo

Implementar un microservicio independiente de procesamiento de pagos que se integre con el backend principal (Django) a través de webhooks seguros. El objetivo es desacoplar la lógica de pagos del servidor principal y utilizar Stripe en modo test para validar transacciones de forma segura.

---

## Arquitectura

El sistema está dividido en dos componentes principales:

### **Backend Principal (Django - farmacia_service)**
- Gestión de inventario, usuarios y ventas
- **No interactúa directamente con Stripe**
- Recibe confirmaciones de pago a través del endpoint interno `/api/pagos/confirmar/`
- Valida las solicitudes usando un header secreto (`X-INTERNAL-SECRET`)

### **Microservicio de Pagos (Express + TypeScript)**
- Servicio independiente en puerto 4000
- Encapsula toda la lógica de Stripe
- Crea PaymentIntents y gestiona webhooks
- Notifica al backend Django cuando un pago es exitoso

---

## Patrón Adapter

Se implementó el patrón **Adapter** para desacoplar la creación de pagos de la implementación específica de Stripe:

### **Interfaz PaymentAdapter**
Define el contrato que cualquier proveedor de pagos debe cumplir:
```typescript
interface PaymentAdapter {
  createPayment(amount: number, reference: string): Promise<PaymentResponse>
}
```

### **Implementación StripeAdapter**
Adaptador concreto que implementa la interfaz usando la API de Stripe PaymentIntents.

### **Beneficio**
- **Desacoplamiento:** El servidor Express no depende directamente de Stripe
- **Flexibilidad:** Se puede cambiar o agregar otros proveedores (PayPal, MercadoPago) sin tocar el código principal
- **Testabilidad:** Se puede crear un mock adapter para pruebas unitarias

---

## Flujo del Pago (Paso a Paso)

```
1. Cliente solicita pago
   ↓
2. POST /pay → Express crea PaymentIntent mediante StripeAdapter
   ↓
3. Express devuelve clientSecret y paymentIntentId
   ↓
4. Cliente confirma el pago en Stripe (con tarjeta de prueba o simulación)
   ↓
5. Stripe genera evento payment_intent.succeeded
   ↓
6. Webhook /webhooks/stripe recibe el evento (validado con firma)
   ↓
7. Express extrae metadata y notifica a Django
   ↓
8. Django valida header X-INTERNAL-SECRET
   ↓
9. Django responde con confirmación (HTTP 200)
```

---

## Seguridad Implementada

### **Validación de Webhook de Stripe**
- Se utiliza `stripe.webhooks.constructEvent()` para validar la firma del evento
- Solo se procesan eventos con firma válida
- Previene solicitudes fraudulentas

### **Autenticación Interna**
- El microservicio incluye un header `X-INTERNAL-SECRET` en cada notificación a Django
- Django valida que el secret coincida con `INTERNAL_SECRET` en settings
- Protege el endpoint `/api/pagos/confirmar/` de accesos no autorizados

### **Variables de Entorno**
```env
STRIPE_SECRET_KEY=sk_test_...        # Clave secreta de Stripe
STRIPE_WEBHOOK_SECRET=whsec_...      # Secret del webhook
INTERNAL_SECRET=token-compartido     # Token de autenticación interna
DJANGO_CONFIRM_URL=http://localhost:8000/api/pagos/confirmar/
PORT=4000
```

---

## Pruebas End-to-End

### **Configuración con Stripe CLI**
```bash
stripe login                                           # Autenticarse
stripe listen --forward-to localhost:4000/webhooks/stripe  # Escuchar webhooks
```

### **Simulación de Pago Exitoso**
```bash
stripe trigger payment_intent.succeeded
```

### **Verificación de Logs**
1. **Express:** Muestra validación de firma y notificación a Django
2. **Django:** Recibe POST con metadata del pago y responde con HTTP 200

### **Testing Manual**
```bash
# Crear PaymentIntent
curl -X POST http://localhost:4000/pay \
  -H "Content-Type: application/json" \
  -d '{"amount": 25.50, "reference": "ORDER-001"}'

# Respuesta esperada
{
  "clientSecret": "pi_xxx_secret_yyy",
  "paymentIntentId": "pi_xxx"
}
```

---

## Separación de Responsabilidades

- **Django:** No conoce detalles de Stripe, solo recibe confirmaciones
- **Express:** Encapsula toda la lógica de Stripe y webhooks
- **Comunicación:** Unidireccional: Express → Django (sin respuesta esperada)

Esta arquitectura permite que el backend principal sea agnóstico al proveedor de pagos utilizado.

---

## Archivos Relevantes

### **Express + TypeScript**
- `payment_service/src/index.ts` – Servidor Express con endpoints `/pay` y `/webhooks/stripe`
- `payment_service/src/adapters/PaymentAdapter.ts` – Interfaz del patrón Adapter
- `payment_service/src/adapters/StripeAdapter.ts` – Implementación concreta para Stripe
- `payment_service/src/config.ts` – Carga de variables de entorno

### **Django**
- `farmacia/views.py` – Endpoint `/api/pagos/confirmar/` (PILAR 2 - Stripe Payment Confirmation)
- `farmacia/urls.py` – Ruta del endpoint de confirmación
- `farmacia_service/settings.py` – Configuración de `INTERNAL_SECRET`

---

## Conclusión

El Pilar 2 implementa un sistema de pagos robusto y seguro utilizando Stripe en modo test, con una arquitectura desacoplada basada en el patrón Adapter y comunicación segura entre microservicios mediante webhooks y autenticación interna.
