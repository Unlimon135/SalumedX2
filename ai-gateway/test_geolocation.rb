# Test de Geolocalización

require_relative '../config/environment'

puts "🧪 Probando Geolocalización de Farmacias\n\n"

# Simular datos de prueba
user_lat = -12.0464  # Lima, Perú (ejemplo)
user_lng = -77.0428

puts "📍 Ubicación de prueba: [#{user_lat}, #{user_lng}]"
puts "   (Lima, Perú)\n\n"

# Test 1: Buscar farmacias cercanas sin filtro
puts "=" * 60
puts "TEST 1: Buscar farmacias cercanas (sin filtro)"
puts "=" * 60

begin
  service = FarmaciaService.new(token: nil)
  farmacias = service.buscar_cercanas(user_lat, user_lng, limit: 5)
  
  if farmacias.empty?
    puts "⚠️  No se encontraron farmacias"
  else
    puts "✅ Se encontraron #{farmacias.size} farmacias:\n"
    farmacias.each_with_index do |farmacia, index|
      puts "#{index + 1}. #{farmacia['nombre']}"
      puts "   📍 #{farmacia['direccion']}"
      puts "   📏 Distancia: #{farmacia['distancia_km']} km"
      puts "   🏥 Productos: #{farmacia['productos']&.size || 0}"
      puts ""
    end
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end

# Test 2: Buscar farmacias con producto específico
puts "\n" + "=" * 60
puts "TEST 2: Buscar farmacias con 'paracetamol'"
puts "=" * 60

begin
  service = FarmaciaService.new(token: nil)
  farmacias = service.buscar_cercanas(user_lat, user_lng, producto_nombre: 'paracetamol', limit: 3)
  
  if farmacias.empty?
    puts "⚠️  No se encontraron farmacias con paracetamol"
  else
    puts "✅ Se encontraron #{farmacias.size} farmacias con paracetamol:\n"
    farmacias.each_with_index do |farmacia, index|
      puts "#{index + 1}. #{farmacia['nombre']}"
      puts "   📍 #{farmacia['direccion']}"
      puts "   📏 Distancia: #{farmacia['distancia_km']} km"
      
      # Mostrar productos que coinciden
      productos = farmacia['productos'] || []
      productos_paracetamol = productos.select do |p|
        nombre = "#{p['nombreGenerico']} #{p['nombreComercial']}".downcase
        nombre.include?('paracetamol')
      end
      
      if productos_paracetamol.any?
        puts "   💊 Productos:"
        productos_paracetamol.each do |p|
          puts "      - #{p['nombreComercial']} (#{p['nombreGenerico']}) - $#{p['precio']} - Stock: #{p['stock']}"
        end
      end
      puts ""
    end
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end

# Test 3: Probar MCP Query
puts "\n" + "=" * 60
puts "TEST 3: Ejecutar MCP Query"
puts "=" * 60

begin
  params = {
    user_lat: user_lat,
    user_lng: user_lng,
    limit: 3
  }
  
  result = MCP::BuscarFarmaciaCercana.execute(params, nil)
  
  puts "Resultado:"
  puts "  Tool: #{result[:tool]}"
  puts "  Success: #{result[:success]}"
  puts "  Count: #{result[:count] || 0}"
  
  if result[:success] && result[:data]
    puts "\n  Farmacias encontradas:"
    result[:data].each_with_index do |farmacia, index|
      puts "    #{index + 1}. #{farmacia['nombre']} - #{farmacia['distancia_km']} km"
    end
  elsif result[:error]
    puts "  Error: #{result[:error]}"
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end

# Test 4: Probar detección del Agente
puts "\n" + "=" * 60
puts "TEST 4: Detección por el Agente AI"
puts "=" * 60

begin
  agent = Agent.new(
    token: nil, 
    context: { user_lat: user_lat, user_lng: user_lng }
  )
  
  mensajes_test = [
    "¿Dónde hay farmacias cerca?",
    "Necesito comprar paracetamol",
    "¿Qué farmacia está más cerca?",
    "Busca ibuprofeno en una botica cercana"
  ]
  
  mensajes_test.each do |mensaje|
    puts "\n📝 Mensaje: '#{mensaje}'"
    tools = agent.send(:detect_tools_needed, mensaje)
    
    if tools.include?('buscar_farmacia_cercana')
      puts "   ✅ Detectado: buscar_farmacia_cercana"
    else
      puts "   ⚠️  No detectado"
    end
    
    puts "   Herramientas: #{tools.join(', ')}"
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n" + "=" * 60
puts "✅ Tests completados"
puts "=" * 60
