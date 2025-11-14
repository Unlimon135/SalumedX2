import http from 'http';

const datos = {
  type: 'PRODUCT_CREATED',
  data: {
    id: 1,
    nombre_comercial: 'Paracetamol 500mg',
    nombre_generico: 'Acetaminofén',
    precio: 5.50,
    mensaje: 'Nuevo producto: Paracetamol 500mg'
  }
};

const body = JSON.stringify(datos);

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

console.log('📤 Enviando notificación:', datos.type);

const req = http.request(opciones, (res) => {
  let responseData = '';
  
  res.on('data', (chunk) => {
    responseData += chunk;
  });
  
  res.on('end', () => {
    console.log('✅ Status Code:', res.statusCode);
    console.log('✅ Response:', responseData);
    console.log('\n✨ Verifica el dashboard en http://localhost:8080/client.html');
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});

req.write(body);
req.end();
