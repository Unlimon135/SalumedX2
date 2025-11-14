import http from 'http';

console.log('🔍 Probando conexión al servidor...');

const opciones = {
  hostname: 'localhost',
  port: 8080,
  path: '/',
  method: 'GET'
};

const req = http.request(opciones, (res) => {
  let responseData = '';
  
  console.log('✅ Conectado. Status:', res.statusCode);
  
  res.on('data', (chunk) => {
    responseData += chunk;
  });
  
  res.on('end', () => {
    console.log('Response:', responseData);
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});

req.end();
