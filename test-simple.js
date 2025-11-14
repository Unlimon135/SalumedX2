#!/usr/bin/env node
// Script simple para enviar notificaciones de prueba al servidor WebSocket
// Uso: node test-simple.js

import http from 'http';

const notificaciones = [
  {
    type: "PRODUCT_CREATED",
    data: {
      id: 1,
      nombre_comercial: "Ibuprofeno 200mg",
      nombre_generico: "Ibuprofeno",
      precio: 3.99,
      mensaje: "Nuevo producto: Ibuprofeno 200mg"
    }
  },
  {
    type: "PHARMACY_CREATED",
    data: {
      id: 1,
      nombre: "Farmacia Santa María",
      direccion: "Calle Principal 456",
      telefono: "555-9999",
      mensaje: "Nueva farmacia: Farmacia Santa María"
    }
  },
  {
    type: "PRODUCT_PHARMACY_RELATION_CREATED",
    data: {
      id: 1,
      producto_id: 1,
      farmacia_id: 1,
      precio: 4.50,
      stock: 50,
      mensaje: "Nuevo precio: Ibuprofeno en Farmacia Santa María"
    }
  }
];

function enviarNotificacion(notificacion, index) {
  const body = JSON.stringify(notificacion);
  
  const opciones = {
    hostname: 'localhost',
    port: 8080,
    path: '/api/notifications',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body)
    }
  };

  const req = http.request(opciones, (res) => {
    console.log(`✅ Notificación ${index + 1} enviada (Status: ${res.statusCode})`);
  });

  req.on('error', (error) => {
    console.error(`❌ Error en notificación ${index + 1}:`, error.message);
  });

  req.write(body);
  req.end();
}

console.log('🚀 Enviando notificaciones de prueba...\n');

notificaciones.forEach((notif, index) => {
  setTimeout(() => {
    enviarNotificacion(notif, index);
  }, index * 1000);
});

console.log('\n✨ Proceso de envío iniciado. Verifica el dashboard en http://localhost:8080/client.html\n');
