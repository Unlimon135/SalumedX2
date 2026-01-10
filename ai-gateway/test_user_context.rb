# Test: Información del Usuario en el Agente

require_relative '../config/environment'
require 'jwt'

puts "🧪 Probando Información del Usuario\n\n"

# Simular un JWT token
def create_test_token(user_data)
  payload = {
    sub: user_data[:user_id],
    username: user_data[:username],
    role: user_data[:role],
    email: user_data[:email],
    exp: Time.now.to_i + 3600
  }
  
  # Nota: En producción, esto debería estar firmado con JWT_SECRET
  # Por ahora solo codificamos para prueba
  require 'base64'
  require 'json'
  
  header = Base64.urlsafe_encode64({ alg: 'HS256', typ: 'JWT' }.to_json).gsub('=', '')
  payload_encoded = Base64.urlsafe_encode64(payload.to_json).gsub('=', '')
  signature = 'test_signature'
  
  "#{header}.#{payload_encoded}.#{signature}"
end

# Test 1: Médico
puts "=" * 60
puts "TEST 1: Usuario MÉDICO"
puts "=" * 60

medico_token = create_test_token(
  user_id: '123',
  username: 'Dr. Juan Pérez',
  role: 'medico',
  email: 'juan@hospital.com'
)

context = {
  user_id: '123',
  username: 'Dr. Juan Pérez',
  role: 'medico',
  user_lat: -12.0464,
  user_lng: -77.0428
}

agent = Agent.new(token: medico_token, context: context)

puts "\n📝 Pregunta: '¿Quién soy?'"
puts "\n🤖 Prompt generado incluye:"
context_data = agent.context.build("¿Quién soy?")
puts context_data[:system_prompt][0..300] + "..."

# Test 2: Paciente
puts "\n\n" + "=" * 60
puts "TEST 2: Usuario PACIENTE"
puts "=" * 60

paciente_token = create_test_token(
  user_id: '456',
  username: 'María López',
  role: 'paciente',
  email: 'maria@gmail.com'
)

context_paciente = {
  user_id: '456',
  username: 'María López',
  role: 'paciente',
  user_lat: -12.0500,
  user_lng: -77.0300
}

agent_paciente = Agent.new(token: paciente_token, context: context_paciente)

puts "\n📝 Pregunta: 'Necesito crear una receta'"
context_data_p = agent_paciente.context.build("Necesito crear una receta")
puts "\n🤖 Prompt generado incluye:"
puts context_data_p[:system_prompt][0..300] + "..."

# Test 3: Farmacéutico
puts "\n\n" + "=" * 60
puts "TEST 3: Usuario FARMACÉUTICO"
puts "=" * 60

farm_token = create_test_token(
  user_id: '789',
  username: 'Carlos Ramírez',
  role: 'farmaceutico',
  email: 'carlos@farmacia.com'
)

context_farm = {
  user_id: '789',
  username: 'Carlos Ramírez',
  role: 'farmaceutico'
}

agent_farm = Agent.new(token: farm_token, context: context_farm)

puts "\n📝 Pregunta: '¿Qué puedo hacer?'"
context_data_f = agent_farm.context.build("¿Qué puedo hacer?")
puts "\n🤖 Prompt generado incluye:"
puts context_data_f[:system_prompt][0..300] + "..."

# Test 4: Con ubicación
puts "\n\n" + "=" * 60
puts "TEST 4: Usuario CON ubicación"
puts "=" * 60

context_ubicacion = {
  user_id: '123',
  username: 'Dr. Juan',
  role: 'medico',
  user_lat: -12.0464,
  user_lng: -77.0428
}

agent_ubicacion = Agent.new(token: medico_token, context: context_ubicacion)

puts "\n📝 Pregunta: '¿Dónde hay farmacias?'"
tools = agent_ubicacion.send(:detect_tools_needed, "¿Dónde hay farmacias?")
puts "\n🔧 Herramientas detectadas: #{tools.join(', ')}"

if tools.include?('buscar_farmacia_cercana')
  puts "✅ Se detectó búsqueda de farmacias cercanas"
  puts "📍 Ubicación disponible: [#{context_ubicacion[:user_lat]}, #{context_ubicacion[:user_lng]}]"
end

# Test 5: Sin ubicación
puts "\n\n" + "=" * 60
puts "TEST 5: Usuario SIN ubicación"
puts "=" * 60

context_sin_ubicacion = {
  user_id: '456',
  username: 'María',
  role: 'paciente'
}

agent_sin_ubicacion = Agent.new(token: paciente_token, context: context_sin_ubicacion)

puts "\n📝 Pregunta: '¿Dónde hay farmacias?'"
context_sin_ub = agent_sin_ubicacion.context.build("¿Dónde hay farmacias?")
puts "\n🤖 Prompt NO incluye ubicación"
if context_sin_ub[:system_prompt].include?('Ubicación')
  puts "❌ ERROR: Se incluyó ubicación cuando no debería"
else
  puts "✅ Correcto: No se incluye ubicación"
end

puts "\n\n" + "=" * 60
puts "✅ Tests completados"
puts "=" * 60
puts "\n💡 El agente personaliza las respuestas según:"
puts "   - Nombre del usuario"
puts "   - Rol (médico, paciente, farmacéutico)"
puts "   - Ubicación (si está disponible)"
