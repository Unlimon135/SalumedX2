# 📦 Proyecto Segundo Parcial – Arquitectura Distribuida

## 📌 Descripción General

Este proyecto corresponde al **Trabajo Autónomo del Segundo Parcial** y extiende el sistema desarrollado en el **Primer Parcial**.

El proyecto base (Primer Parcial) ya cuenta con:
- API REST
- API GraphQL
- Comunicación en tiempo real mediante WebSockets
- Frontend funcional

En este segundo parcial se incorporan **cuatro pilares obligatorios**, enfocados en **microservicios, interoperabilidad B2B, automatización de eventos e inteligencia artificial**, manteniendo una arquitectura distribuida, escalable y documentada.

---

## 🧱 Pilares del Proyecto

## 🔐 Pilar 1: Microservicio de Autenticación (15%)

Se debe implementar un **microservicio independiente de autenticación**, encargado exclusivamente del manejo de usuarios y seguridad.

### Funcionalidades obligatorias:
- Autenticación basada en **JWT**
- Uso de **Access Tokens** y **Refresh Tokens**
- Validación local de tokens en los demás servicios (sin llamadas constantes al Auth Service)
- Base de datos propia
- Gestión de tokens revocados (blacklist)
- Rate limiting para evitar ataques

### Endpoints obligatorios:
- POST `/auth/register`
- POST `/auth/login`
- POST `/auth/logout`
- POST `/auth/refresh`
- GET `/auth/me`
- POST `/auth/validate`

### Entidades de base de datos:
- Users
- RefreshTokens
- RevokedTokens

---

## 💳 Pilar 2: Webhooks e Interoperabilidad B2B (20%)

Se debe desarrollar un **sistema de pagos interoperable** aplicando el **Adapter Pattern**, permitiendo cambiar de proveedor sin modificar la lógica principal.

### Requisitos técnicos:
- Interfaz común `PaymentProvider`
- Implementaciones:
  - MockAdapter (obligatorio)
  - StripeAdapter o MercadoPago (opcional)
- Normalización de eventos de pago
- API para registro de webhooks externos
- Autenticación de webhooks mediante **HMAC-SHA256**
- Integración bidireccional con otro grupo (mini backend externo)

### Endpoints principales:
- POST `/partners/register`
- POST `/webhooks/receive`

### Consideraciones:
- Se debe coordinar con otro grupo
- Definir contrato de eventos
- Implementar pruebas de interoperabilidad

---

## 🤖 Pilar 3: Chatbot con IA usando MCP (20%)

Se implementa un **asistente de inteligencia artificial** basado en **Model Context Protocol (MCP)**.

### Requisitos:
- LLM Adapter abstracto (Strategy Pattern)
- Implementaciones posibles:
  - OpenAI Adapter
  - Gemini Adapter
- Soporte multimodal:
  - Texto
  - Imágenes
  - Archivos PDF
- Interfaz de chat integrada en el frontend

### Herramientas MCP obligatorias:

#### Consultas:
- buscar_productos
- ver_receta

#### Acciones:
- crear_receta
- actualizar_stock

#### Reporte:
- resumen_ventas

---

## 🔄 Pilar 4: n8n – Event Bus y Automatización (15%)

Se utiliza **n8n** como **orquestador central de eventos** del sistema.

### Workflows obligatorios:
1. Payment Handler
2. Partner Handler
3. MCP Input Handler
4. Scheduled Tasks (cron jobs)

### Funcionalidades:
- Comunicación entre microservicios
- Integración con WebSockets
- Automatización de procesos
- Exportación de workflows en formato JSON

---

## 🏗️ Arquitectura del Sistema

### Frontend:
- Chat UI
- Módulo de pagos
- Dashboard general

### Backend / Servicios:
- API Gateway / GraphQL
- Auth Service
- Payment Service
- AI Orchestrator (MCP)
- WebSocket Server

### Automatización:
- n8n como Event Bus

---

## 👥 División del Trabajo (3 Integrantes)

### 🔵 Programador 1 – Backend Core y Autenticación
- Implementación completa del Auth Service
- JWT y Refresh Tokens
- Middleware de autenticación
- Integración con GraphQL
- Configuración Docker y networking

### 🟢 Programador 2 – Pagos y Webhooks
- Payment Service con Adapter Pattern
- Sistema de webhooks con HMAC-SHA256
- Integración B2B con otro grupo
- Workflow de pagos en n8n

### 🟡 Programador 3 – IA, n8n y Frontend
- AI Orchestrator con MCP
- LLM Adapters
- Implementación de herramientas MCP
- Workflows en n8n
- Chat UI y notificaciones en tiempo real

---

## 🐳 Docker y Entorno

El proyecto utiliza **Docker Compose** para levantar todos los servicios:

- auth-service
- payment-service
- ai-orchestrator
- graphql-api
- websocket-server
- n8n
- frontend

Todos los servicios se comunican dentro de una red privada de Docker.

---

## 📎 Consideraciones Finales

- Arquitectura basada en microservicios
- Comunicación segura entre servicios
- Uso de patrones de diseño
- Sistema completamente funcional y demostrable
- Documentación clara para facilitar mantenimiento y escalabilidad

---

## ✅ Objetivo del Proyecto

Demostrar el uso práctico de:
- Microservicios
- Autenticación moderna
- Interoperabilidad B2B
- Automatización de eventos con n8n
- Inteligencia Artificial aplicada
