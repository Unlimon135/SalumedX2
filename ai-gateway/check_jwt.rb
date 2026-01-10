# Script para verificar contenido del JWT Token

require 'base64'
require 'json'

puts "🔍 Verificador de JWT Token\n\n"

def decode_jwt(token)
  begin
    parts = token.split('.')
    
    if parts.length != 3
      puts "❌ Token inválido: debe tener 3 partes separadas por puntos"
      return nil
    end
    
    # Decodificar header
    header_encoded = parts[0]
    header_json = Base64.urlsafe_decode64(header_encoded + '=' * (4 - header_encoded.length % 4))
    header = JSON.parse(header_json)
    
    # Decodificar payload
    payload_encoded = parts[1]
    payload_json = Base64.urlsafe_decode64(payload_encoded + '=' * (4 - payload_encoded.length % 4))
    payload = JSON.parse(payload_json)
    
    puts "✅ Token decodificado exitosamente\n\n"
    
    puts "=" * 60
    puts "HEADER"
    puts "=" * 60
    puts JSON.pretty_generate(header)
    
    puts "\n" + "=" * 60
    puts "PAYLOAD (Datos del Usuario)"
    puts "=" * 60
    puts JSON.pretty_generate(payload)
    
    puts "\n" + "=" * 60
    puts "CAMPOS IMPORTANTES"
    puts "=" * 60
    
    # User ID
    user_id = payload['sub'] || payload['user_id'] || payload['id']
    puts "👤 User ID: #{user_id || '❌ NO ENCONTRADO'}"
    
    # Username
    username = payload['username'] || payload['name'] || payload['user_name'] || 
               payload['nombre'] || payload['full_name'] || payload['displayName']
    puts "📝 Username: #{username || '❌ NO ENCONTRADO'}"
    
    # Email
    email = payload['email'] || payload['correo']
    puts "📧 Email: #{email || '❌ NO ENCONTRADO'}"
    
    # Role
    role = payload['role'] || payload['tipo_usuario'] || payload['user_role'] || payload['tipo']
    puts "🎭 Role: #{role || '❌ NO ENCONTRADO (default: paciente)'}"
    
    # Expiración
    if payload['exp']
      exp_time = Time.at(payload['exp'])
      now = Time.now
      if exp_time > now
        diff = ((exp_time - now) / 60).to_i
        puts "⏰ Expira en: #{diff} minutos (#{exp_time})"
      else
        puts "❌ Token EXPIRADO hace #{((now - exp_time) / 60).to_i} minutos"
      end
    else
      puts "⚠️ Sin fecha de expiración"
    end
    
    puts "\n" + "=" * 60
    puts "TODOS LOS CAMPOS DISPONIBLES"
    puts "=" * 60
    payload.each do |key, value|
      puts "  #{key}: #{value}"
    end
    
    return payload
    
  rescue StandardError => e
    puts "❌ Error decodificando token: #{e.message}"
    puts e.backtrace.first(3)
    return nil
  end
end

# Instrucciones de uso
puts <<~INSTRUCTIONS
  Para verificar tu token JWT:
  
  1. Abre el chat en el navegador
  2. Abre DevTools (F12) → Console
  3. Ejecuta: localStorage.getItem('authToken')
  4. Copia el token (todo el texto entre comillas)
  5. Pega aquí abajo cuando se te pida
  
  O puedes ejecutar este script con el token como argumento:
  ruby check_jwt.rb "tu_token_aqui"

INSTRUCTIONS

if ARGV[0]
  puts "Token recibido como argumento\n\n"
  decode_jwt(ARGV[0])
else
  puts "Pega tu token JWT y presiona Enter:"
  puts "(El token debe ser una cadena como: eyJhbGciOiJIUzI1NiIsInR5cCI...)"
  print "\nToken: "
  
  token = gets.chomp.strip
  
  if token.empty?
    puts "\n❌ No se proporcionó ningún token"
    exit 1
  end
  
  puts "\n"
  decode_jwt(token)
end

puts "\n\n💡 Tip: Si el username no aparece, verifica qué campo tiene el nombre"
puts "     en la sección 'PAYLOAD' y actualiza el código para buscarlo."
