# Pilar 2 – Sistema de Pagos y Webhooks

## ¿Qué es el Pilar 2?

El Pilar 2 implementa un sistema de pagos con interoperabilidad B2B entre microservicios. Su objetivo académico es demostrar:
- **Desacoplamiento arquitectónico:** El backend principal no gestiona pagos directamente.
- **Patrón Adapter:** Abstracción de proveedores de pago (Stripe, Mock, etc.).
- **Webhooks seguros:** Comunicación bidireccional entre grupos mediante HMAC-SHA256.
- **Normalización de eventos:** Formato estándar independiente del proveedor.

Este Pilar representa el **20% de la calificación** del segundo parcial y requiere interoperabilidad con al menos otro grupo.

---

## Arquitectura General

### **Componentes:**
```
┌─────────────────┐         ┌─────────────────────┐         ┌──────────────┐
│   Django        │◄────────│  Payment Service    │────────►│  Stripe      │
│  (farmacia)     │         │  (Express + TS)     │         │  (Test Mode) │
└─────────────────┘         └─────────────────────┘         └──────────────┘
                                    │
                                    ▼
                            ┌─────────────────┐
                            │  Partner Groups │
                            │  (via Webhooks) │
                            └─────────────────┘
```

### **Django (farmacia_service)**
- Gestión de inventario, usuarios y ventas
- **No interactúa directamente con Stripe**
- Recibe confirmaciones en `/api/pagos/confirmar/` con header `X-INTERNAL-SECRET`
- Código nuevo comentado con "PILAR 2 - Stripe Payment Confirmation"

### **Payment Service (Express + TypeScript, puerto 4000)**
- Microservicio independiente para procesamiento de pagos
- Encapsula toda la lógica de proveedores de pago
- Gestiona webhooks de Stripe/Mock
- Dispara webhooks a partners registrados con HMAC-SHA256
- Normaliza eventos a formato estándar

---

## Componentes Implementados

### **1. Patrón Adapter**

**Problema:** Acoplar Stripe directamente al código → difícil cambiar de proveedor.

**Solución:**
- `PaymentAdapter` (interfaz): Define contrato de pagos
- `StripeAdapter`: Implementación real con Stripe PaymentIntents
- `MockAdapter`: Implementación simulada para desarrollo/testing

**Variable de entorno:** `PAYMENT_PROVIDER=stripe|mock`

```typescript
// Selecciona automáticamente el adapter
if (config.paymentProvider === 'mock') {
  adapter = new MockAdapter();
} else {
  adapter = new StripeAdapter(stripe);
}
```

### **2. Normalización de Webhooks**

**Problema:** Cada proveedor usa formato diferente de eventos.

**Solución:** `WebhookNormalizer` convierte eventos a formato estándar:

```typescript
interface NormalizedWebhookEvent {
  type: 'payment.succeeded' | 'payment.failed',
  reference: string,
  amount: number,
  paymentIntentId: string,
  status: string,
  source: 'stripe' | 'mock' | 'mercadopago',
  timestamp: number
}
```

Soporta: Stripe, Mock, MercadoPago (placeholder).

### **3. Registro de Partners**

**Problema:** ¿Cómo otros grupos se registran para recibir webhooks?

**Solución:** `PartnerManager` gestiona partners en memoria:

```typescript
interface Partner {
  id: string,                  // Generado automáticamente
  name: string,               // Nombre del grupo
  webhookUrl: string,         // Dónde enviar webhooks
  eventosSuscritos: string[], // Eventos que quiere recibir
  hmacSecret: string,         // Secret único para firmar
  isActive: boolean
}
```

Storage en **memoria** (académico, demostrable localmente).

### **4. Autenticación HMAC-SHA256**

**Problema:** ¿Cómo validar que webhooks vengan realmente de nosotros?

**Solución:** `HMACService` firma y verifica webhooks:

- **Firma:** Generar `X-Signature: hash(payload, secret)` al enviar
- **Verificación:** Validar que `hash(payload_recibido, secret) === X-Signature`
- **Seguridad:** Secret único por partner, nunca se expone

Uso: `HMACService.signPayload()` y `HMACService.verifySignature()`

### **5. Webhooks Bidireccionales**

**Problema:** ¿Cómo comunicamos pagos exitosos a otros grupos?

**Solución:** `WebhookDispatcher` envía eventos a partners:

```typescript
// Cuando ocurre payment.succeeded:
1. Normalizar evento
2. Obtener partners suscritos a "payment.succeeded"
3. Para cada partner:
   - Generar firma HMAC con secret del partner
   - Enviar POST con header X-Signature
   - Reintentar una vez si falla
4. Notificar a Django (INTERNAL_SECRET)
```

Sin dependencia de grupo real: Usar endpoint `/webhooks/test/trigger` para disparar eventos.

---

## Flujo del Sistema (Paso a Paso)

### **Escenario: Pago exitoso**

```
1. Cliente solicita pago
   POST /pay → {amount: 50, reference: "ORDER-001"}

2. Payment Service crea PaymentIntent
   StripeAdapter.createPayment()
   → Responde: {clientSecret, paymentIntentId}

3. Cliente completa pago en Stripe
   (o simula con `stripe trigger payment_intent.succeeded`)

4. Stripe envía webhook
   POST /webhooks/stripe (con firma Stripe)

5. Payment Service valida firma
   stripe.webhooks.constructEvent()

6. Evento se normaliza
   WebhookNormalizer.normalizeStripeEvent()
   → {type: "payment.succeeded", reference: "ORDER-001", ...}

7. Enviar a partners suscritos
   WebhookDispatcher.dispatchEvent()
   → Firmar con HMAC del partner
   → POST a webhookUrl con header X-Signature

8. Notificar a Django
   POST http://localhost:8000/api/pagos/confirmar/
   Con header X-INTERNAL-SECRET

9. Django confirma pago
   Responde: {"message": "PILAR 2 - Stripe Payment Confirmation: pago confirmado"}
```

---

## Endpoints Principales

### **Pagos (Cliente)**

- `POST /pay` - Crear PaymentIntent
  - Input: `{amount: number, reference: string}`
  - Output: `{clientSecret, paymentIntentId}`

### **Webhooks (Sistemas externos)**

- `POST /webhooks/stripe` - Recibir eventos de Stripe (solo en modo `stripe`)
  - Valida firma con `STRIPE_WEBHOOK_SECRET`
  
- `POST /webhooks/mock` - Simular webhooks (solo en modo `mock`)
  - Input: evento normalizado con partnerId

### **Partners (Registro de grupos)**

- `POST /partners/register` - Registrar nuevo grupo
  - Input: `{name, webhookUrl, eventosSuscritos}`
  - Output: `{id, hmacSecret, ...}`

- `GET /partners` - Listar partners registrados

- `DELETE /partners/:id` - Eliminar partner

- `POST /webhooks/partner` - Recibir webhook de otro grupo
  - Valida: partnerId, firma HMAC en `X-Signature`, suscripción a evento

### **Testing & Debugging**

- `POST /webhooks/test/trigger` - Disparar evento de prueba a partners
  - Input: `{eventType: "payment.succeeded"}`
  - Útil para demo sin Stripe real

- `POST /hmac/sign` - Generar firma (testing)

- `POST /hmac/verify` - Verificar firma (testing)

- `GET /health` - Health check

---

## Variables de Entorno

```env
# Modo de operación
PAYMENT_PROVIDER=mock          # 'stripe' para Stripe real, 'mock' para desarrollo

# Solo requeridas si PAYMENT_PROVIDER=stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Compartida entre payment_service y Django
INTERNAL_SECRET=super-internal-token

# URLs
DJANGO_CONFIRM_URL=http://localhost:8000/api/pagos/confirmar/
PORT=4000
```

---

## Cómo Probar (Demo Local)

### **Setup inicial:**

```bash
# 1. Instalar dependencias
cd payment_service
npm install

# 2. Crear .env
cp .env.example .env
# Editar .env con valores

# 3. Iniciar payment_service
npm run dev
# Debería mostrar: Payment service listening on port 4000
```

### **En modo mock (sin Stripe):**

```bash
# Registrar partner de prueba
curl -X POST http://localhost:4000/partners/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Partner Test",
    "webhookUrl": "http://localhost:5000/api/webhooks",
    "eventosSuscritos": ["payment.succeeded"]
  }'
# Guarda el hmacSecret

# Disparar evento de prueba
curl -X POST http://localhost:4000/webhooks/test/trigger \
  -H "Content-Type: application/json" \
  -d '{"eventType": "payment.succeeded"}'

# Observar logs mostrando envío de webhook firmado
```

### **Con Stripe (modo producción):**

```bash
# 1. Obtener claves de Stripe Dashboard
# 2. Configurar PAYMENT_PROVIDER=stripe
# 3. Instalar Stripe CLI: stripe login
# 4. Escuchar webhooks: stripe listen --forward-to localhost:4000/webhooks/stripe
# 5. Copiar STRIPE_WEBHOOK_SECRET a .env
# 6. Reiniciar payment_service
# 7. Crear pago: POST /pay
# 8. Completar pago o trigger: stripe trigger payment_intent.succeeded
```

---

## Notas Académicas

### **Simplificaciones intencionadas:**

✓ **Storage en memoria:** No usa base de datos (academia, demostrabilidad)
✓ **Mock en modo test:** No requiere Stripe real para testing  
✓ **Sin grupo real requerido:** Endpoint de testing dispara eventos automáticamente
✓ **1 reintento:** Suficiente para demostración académica
✓ **Sin persistencia:** Partners se pierden al reiniciar (aceptable para parcial)

### **Implementación académica:**

- Código claro y comentado como "PILAR 2 - [Componente]"
- Logging detallado para entender el flujo
- Endpoints de testing incluidos
- No hay sobre-ingeniería

### **Cómo explicar al profesor:**

> "El Pilar 2 demuestra patrón Adapter (desacoplamiento de Stripe), normalización de eventos (formato común), registro de partners (interoperabilidad B2B), HMAC-SHA256 (seguridad en webhooks) y webhooks bidireccionales (comunicación entre grupos). Funciona completamente en local sin depender de otros grupos."

---

## Archivos del Pilar 2

### **En payment_service/src:**

```
adapters/
├── PaymentAdapter.ts       (Interfaz)
├── StripeAdapter.ts        (Implementación Stripe)
└── MockAdapter.ts          (Implementación Mock)

services/
├── WebhookNormalizer.ts    (Normalización de eventos)
├── PartnerManager.ts       (Gestión de partners)
├── HMACService.ts          (Firma y verificación HMAC)
└── WebhookDispatcher.ts    (Envío de webhooks)

types/
├── NormalizedEvent.ts      (Interfaz de evento normalizado)
└── Partner.ts              (Interfaz de partner)

index.ts                     (Endpoints principales)
config.ts                    (Configuración con PAYMENT_PROVIDER)
```

### **En Django (farmacia):**

```
views.py                     (POST /api/pagos/confirmar/ con "PILAR 2" comentario)
urls.py                      (Ruta del endpoint con "PILAR 2" comentario)
```

---

## Conclusión

El Pilar 2 implementa un sistema de pagos robusto, desacoplado y seguro que cumple los requisitos académicos de:
- **Adapter Pattern** ✓
- **Webhooks seguros con HMAC** ✓
- **Normalización de eventos** ✓
- **Interoperabilidad B2B** ✓
- **Separación de servicios** ✓

Todo el código es simple, demostrable localmente y adecuado para una explicación clara al profesor.

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
