#!/usr/bin/env ruby
# Script de prueba para la base de datos SQLite

require_relative 'infra/db'

puts "🧪 Iniciando prueba de base de datos SQLite\n\n"

# Inicializar DB
db = DB.instance

# Guardar algunos mensajes de prueba
puts "📝 Guardando mensajes de prueba..."
db.save_message('user123', '¿Qué productos tienes?', 'user')
db.save_message('user123', 'Tenemos paracetamol, ibuprofeno...', 'assistant')
db.save_message('user123', 'Busca paracetamol', 'user')
db.save_message('user456', 'Hola, necesito ayuda', 'user')

puts "\n📊 Estadísticas:"
stats = db.stats
puts "  - Total mensajes: #{stats[:total_messages]}"
puts "  - Usuarios únicos: #{stats[:unique_users]}"

puts "\n📜 Historial de user123:"
history = db.get_history('user123', 10)
history.reverse.each do |row|
  role = row[3] == 'user' ? '👤' : '🤖'
  puts "  #{role} [#{Time.at(row[4])}] #{row[2]}"
end

puts "\n📜 Historial de user456:"
history = db.get_history('user456', 10)
history.reverse.each do |row|
  role = row[3] == 'user' ? '👤' : '🤖'
  puts "  #{role} [#{Time.at(row[4])}] #{row[2]}"
end

puts "\n🗑️ Limpiando historial de user456..."
db.clear_history('user456')

puts "\n📊 Estadísticas después de limpiar:"
stats = db.stats
puts "  - Total mensajes: #{stats[:total_messages]}"
puts "  - Usuarios únicos: #{stats[:unique_users]}"

puts "\n✅ Prueba completada exitosamente!"
puts "📁 Base de datos: #{Dir.pwd}/chat_history.db"
