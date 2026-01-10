# 🎯 Ejemplos de Respuestas Mejoradas por Rol

## Comparación: Antes vs Después

### 📊 Escenario 1: Paciente intenta crear receta

**Antes:**
```
Usuario (Paciente): Quiero crear una receta
AI: Error: No tienes permisos para crear recetas.
```

**Después (MEJORADO):**
```
Usuario (María López - Paciente): Quiero crear una receta

AI: Hola María 👋

Entiendo que necesitas una receta médica. Sin embargo, solo los médicos pueden crear recetas en el sistema SaluMedX, esto es por seguridad y regulación médica.

📋 ¿Qué puedo hacer por ti?

✅ Consultar tus recetas existentes
✅ Buscar medicamentos disponibles
✅ Encontrar farmacias cercanas donde comprar
✅ Ver información sobre medicamentos

¿Te gustaría que te ayude con alguna de estas opciones?
```

---

### 📊 Escenario 2: Médico busca medicamento

**Antes:**
```
Usuario (Médico): Busca paracetamol
AI: Encontré 3 productos con paracetamol.
[datos JSON]
```

**Después (MEJORADO):**
```
Usuario (Dr. Juan Pérez - Médico): Busca paracetamol

AI: Buenos días Dr. Juan 👨‍⚕️

Encontré **3 presentaciones de paracetamol** disponibles:

1. **Paracetamol 500mg** (Genérico)
   💊 Tabletas
   💰 Precio: $5.50
   📦 Stock: 150 unidades
   
2. **Tylenol 500mg** (Marca)
   💊 Tabletas
   💰 Precio: $12.00
   📦 Stock: 85 unidades
   
3. **Paracetamol 1g** (Genérico)
   💊 Tabletas
   💰 Precio: $8.75
   📦 Stock: 120 unidades

¿Deseas crear una receta con alguno de estos productos o necesitas más información?
```

---

### 📊 Escenario 3: Farmacéutico consulta stock

**Antes:**
```
Usuario (Farmacéutico): ¿Cuánto stock hay de ibuprofeno?
AI: [datos]
```

**Después (MEJORADO):**
```
Usuario (Carlos Ramírez - Farmacéutico): ¿Cuánto stock hay de ibuprofeno?

AI: Hola Carlos 💊

📊 **Inventario actual de Ibuprofeno:**

| Presentación | Stock | Estado | Precio |
|--------------|-------|--------|--------|
| Ibuprofeno 400mg | 245 | ✅ Normal | $7.50 |
| Ibuprofeno 600mg | 12 | ⚠️ Bajo | $10.00 |
| Advil 400mg | 89 | ✅ Normal | $15.00 |

**Alertas:**
⚠️ El Ibuprofeno 600mg está por debajo del nivel mínimo (15 unidades)

¿Necesitas actualizar el inventario o generar una orden de compra?
```

---

### 📊 Escenario 4: Usuario SIN ubicación busca farmacias

**Antes:**
```
Usuario: ¿Dónde hay farmacias?
AI: Error: ubicación no disponible
```

**Después (MEJORADO):**
```
Usuario (María López - Paciente): ¿Dónde hay farmacias?

AI: Hola María 📍

Para mostrarte las farmacias más cercanas, necesito acceso a tu ubicación GPS.

🔧 **¿Cómo activar tu ubicación?**

1. Busca el ícono 🔒 en la barra de direcciones del navegador
2. Click en "Permisos del sitio"
3. Activa "Ubicación"
4. Recarga la página

Una vez activada, podré mostrarte:
✅ Las 5 farmacias más cercanas
✅ Distancia exacta desde tu ubicación
✅ Productos disponibles en cada farmacia

¿Hay algo más en lo que pueda ayudarte mientras tanto?
```

---

### 📊 Escenario 5: Paciente busca farmacia CON ubicación

**Antes:**
```
Usuario: ¿Dónde puedo comprar amoxicilina?
AI: Farmacias encontradas: [JSON]
```

**Después (MEJORADO):**
```
Usuario (María López - Paciente): ¿Dónde puedo comprar amoxicilina?

AI: Hola María 📍

Encontré **3 farmacias cercanas** que tienen amoxicilina disponible:

🏥 **1. Farmacia San Juan**
   📍 Av. Principal 123
   📏 0.5 km de ti (6 minutos caminando)
   💊 Amoxicilina 500mg - Stock: 45 unidades
   💰 $12.50

🏥 **2. Botica MedSalud**
   📍 Jr. Libertad 456
   📏 1.2 km de ti (15 minutos caminando)
   💊 Amoxicilina 500mg - Stock: 28 unidades
   💰 $11.00

🏥 **3. Farmacia Universal**
   📍 Av. Los Heroes 789
   📏 2.3 km de ti (25 minutos caminando)
   💊 Amoxicilina 500mg - Stock: 67 unidades
   💰 $13.50

⚠️ **Recuerda:** La amoxicilina requiere receta médica. Asegúrate de tener tu prescripción antes de ir a la farmacia.

¿Necesitas indicaciones para llegar a alguna?
```

---

### 📊 Escenario 6: Médico crea receta

**Antes:**
```
Usuario (Médico): Crea receta para Juan con paracetamol
AI: Receta creada ID: 123
```

**Después (MEJORADO):**
```
Usuario (Dr. Juan Pérez - Médico): Crea receta para paciente Juan con paracetamol

AI: Perfecto Dr. Juan 👨‍⚕️

He creado la receta médica:

📋 **Receta N° 123**
━━━━━━━━━━━━━━━━━━━━━━━━━
👤 Paciente: Juan [Apellido]
👨‍⚕️ Médico: Dr. Juan Pérez
📅 Fecha: 9 de Enero, 2026

**Prescripción:**
💊 Paracetamol 500mg
📦 Cantidad: [pendiente especificar]
⏰ Dosis: [pendiente especificar]

**Estado:** ✅ Creada

━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ **Falta información:** 
Para completar la receta, necesito:
- Cantidad a dispensar
- Posología (dosis y frecuencia)
- Duración del tratamiento

¿Deseas agregar estos detalles ahora?
```

---

### 📊 Escenario 7: Admin consulta reportes

**Antes:**
```
Usuario (Admin): Muestra ventas del mes
AI: [JSON con datos]
```

**Después (MEJORADO):**
```
Usuario (Admin): Muestra ventas del mes

AI: Hola Administrador 📊

**Reporte de Ventas - Enero 2026**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💰 **Resumen Financiero:**
- Ingresos totales: $45,280.00
- Transacciones: 1,247
- Ticket promedio: $36.31
- Crecimiento vs mes anterior: +12.5% 📈

📦 **Productos más vendidos:**
1. Paracetamol 500mg - 456 unidades
2. Ibuprofeno 400mg - 389 unidades
3. Amoxicilina 500mg - 234 unidades

📍 **Ventas por ubicación:**
- Farmacia Central: $18,500 (41%)
- Farmacia Norte: $15,200 (33%)
- Farmacia Sur: $11,580 (26%)

📅 **Tendencias:**
- Mejor día: Viernes 15 ($2,450)
- Hora pico: 10am - 12pm
- Categoría líder: Analgésicos

¿Necesitas un análisis más detallado de algún aspecto específico?
```

---

## 🎯 Mejoras Implementadas

### 1. **Personalización**
- ✅ Usa el nombre del usuario
- ✅ Adapta tono según rol
- ✅ Emojis contextuales

### 2. **Manejo de Errores**
- ✅ Mensajes empáticos
- ✅ Explica por qué no puede hacer algo
- ✅ Ofrece alternativas útiles

### 3. **Formato Rico**
- ✅ Tablas y listas organizadas
- ✅ Separadores visuales
- ✅ Iconos descriptivos

### 4. **Contexto**
- ✅ Considera el rol en cada respuesta
- ✅ Usa ubicación cuando está disponible
- ✅ Recuerda permisos y limitaciones

### 5. **Proactividad**
- ✅ Sugiere próximos pasos
- ✅ Hace preguntas de seguimiento
- ✅ Ofrece información adicional relevante
