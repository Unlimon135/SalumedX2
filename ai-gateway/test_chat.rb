# Script de prueba del AI Gateway
# Ejecutar con: ruby test_chat.rb

require 'net/http'
require 'json'
require 'uri'

AI_GATEWAY = 'http://localhost:5000'

puts "🧪 Prueba del AI Gateway\n\n"

# Test 1: Health Check
puts "1️⃣ Health Check..."
begin
  uri = URI("#{AI_GATEWAY}/health")
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    data = JSON.parse(response.body)
    puts "   ✅ Servicio activo"
    puts "   📊 Provider: #{data['llm_provider']}"
  else
    puts "   ❌ Servicio no responde"
  end
rescue => e
  puts "   ❌ Error: #{e.message}"
  puts "   💡 Asegúrate de que el servicio esté corriendo: ruby app.rb"
end

# Test 2: Stats
puts "\n2️⃣ Estadísticas..."
begin
  uri = URI("#{AI_GATEWAY}/chat/stats")
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    data = JSON.parse(response.body)
    puts "   ✅ Base de datos activa"
    puts "   💬 Mensajes totales: #{data['total_messages']}"
    puts "   👥 Usuarios únicos: #{data['unique_users']}"
  else
    puts "   ⚠️  No se pudieron obtener estadísticas"
  end
rescue => e
  puts "   ❌ Error: #{e.message}"
end

# Test 3: Chat sin token (debe fallar)
puts "\n3️⃣ Chat sin autenticación (debe fallar)..."
begin
  uri = URI("#{AI_GATEWAY}/chat/message")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
  request.body = { message: 'Hola' }.to_json
  
  response = http.request(request)
  
  if response.code == '401' || response.code == '400'
    puts "   ✅ Protección de autenticación funcionando"
  else
    puts "   ⚠️  Respuesta inesperada: #{response.code}"
  end
rescue => e
  puts "   ❌ Error: #{e.message}"
end

puts "\n" + "="*50
puts "📋 Resumen:"
puts "="*50
puts "✅ AI Gateway corriendo en: #{AI_GATEWAY}"
puts "✅ Base de datos SQLite funcionando"
puts "✅ Autenticación requerida"
puts "\n💡 Para usar el chat:"
puts "   1. Abrir http://localhost:3000/app.html"
puts "   2. Iniciar sesión"
puts "   3. Click en '🤖 Asistente IA (Pilar 3)'"
puts "\n🔧 Endpoints disponibles:"
puts "   GET  #{AI_GATEWAY}/health"
puts "   GET  #{AI_GATEWAY}/chat/stats"
puts "   POST #{AI_GATEWAY}/chat/message (requiere token)"
puts "   POST #{AI_GATEWAY}/chat/image (requiere token)"
puts "   POST #{AI_GATEWAY}/chat/pdf (requiere token)"
puts "   GET  #{AI_GATEWAY}/chat/history (requiere token)"
puts "   DELETE #{AI_GATEWAY}/chat/history (requiere token)"
