// 🔍 Script de Diagnóstico - Pegar en la Consola del Navegador

console.log('🔍 Iniciando diagnóstico...\n');

// 1. Verificar que Vue está cargado
if (typeof Vue !== 'undefined') {
  console.log('✅ Vue cargado:', Vue.version);
} else {
  console.error('❌ Vue NO está cargado');
}

// 2. Verificar que la app está montada
if (typeof app !== 'undefined') {
  console.log('✅ App montada');
  
  // 3. Verificar propiedades de data
  console.log('\n📊 Propiedades de data:');
  console.log('  messages:', Array.isArray(app.messages) ? `Array(${app.messages.length})` : 'NO DEFINIDO');
  console.log('  userLocation:', app.userLocation !== undefined ? 'DEFINIDO' : '❌ NO DEFINIDO');
  console.log('  locationError:', app.locationError !== undefined ? 'DEFINIDO' : '❌ NO DEFINIDO');
  console.log('  loading:', app.loading);
  console.log('  username:', app.username);
  
  // 4. Verificar métodos
  console.log('\n🔧 Métodos:');
  console.log('  sendMessage:', typeof app.sendMessage === 'function' ? '✅ Function' : '❌ NO DEFINIDO');
  console.log('  getMessageIcon:', typeof app.getMessageIcon === 'function' ? '✅ Function' : '❌ NO DEFINIDO');
  console.log('  getMessageAuthor:', typeof app.getMessageAuthor === 'function' ? '✅ Function' : '❌ NO DEFINIDO');
  console.log('  requestLocation:', typeof app.requestLocation === 'function' ? '✅ Function' : '❌ NO DEFINIDO');
  
  // 5. Probar métodos
  if (typeof app.getMessageIcon === 'function') {
    console.log('\n🧪 Probando getMessageIcon:');
    console.log('  user:', app.getMessageIcon('user'));
    console.log('  assistant:', app.getMessageIcon('assistant'));
    console.log('  system:', app.getMessageIcon('system'));
  }
  
  if (typeof app.getMessageAuthor === 'function') {
    console.log('\n🧪 Probando getMessageAuthor:');
    console.log('  user:', app.getMessageAuthor('user'));
    console.log('  assistant:', app.getMessageAuthor('assistant'));
    console.log('  system:', app.getMessageAuthor('system'));
  }
  
  // 6. Ver configuración
  console.log('\n⚙️ Configuración:');
  console.log('  AI_GATEWAY_URL:', app.AI_GATEWAY_URL);
  console.log('  API_URL:', app.API_URL);
  
  console.log('\n✅ Diagnóstico completado');
  
} else {
  console.error('❌ App NO está montada - Vue no encontró #app');
}

// 7. Verificar errores en consola
console.log('\n📋 Si hay errores arriba, revísalos.');
console.log('💡 Para recargar sin caché: Ctrl + Shift + R (Windows) o Cmd + Shift + R (Mac)');
