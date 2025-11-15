# file: environment.rb
# =============================================
# 🔹 Carga de entorno y dependencias
# =============================================
require 'bundler/setup'
require 'bundler'
require 'dotenv/load'

# Compatibilidad: Puma 7 usa Bundler::ORIGINAL_ENV, que puede no existir en algunas versiones
if defined?(Bundler) && !Bundler.const_defined?(:ORIGINAL_ENV)
	module Bundler
		ORIGINAL_ENV = ENV.to_h.freeze
	end
end

require 'sinatra'
require 'json'
require 'graphql'
require 'httparty'
require 'batch_loader'
require 'rack/cors'

# =============================================
# 🔹 Configuración del servidor (REST base)
# =============================================
require_relative '../config/server_config'

# =============================================
# 🔹 Carga de servicios y resolvers
# =============================================
Dir[File.join(__dir__, "..", "models", "*.rb")].each { |f| require f }
Dir[File.join(__dir__, "..", "service", "*.rb")].each { |f| require f }
Dir[File.join(__dir__, "..", "resolvers", "*.rb")].each { |f| require f }

# =============================================
# 🔹 Cargar primero los tipos (para inicializar el módulo Types)
# =============================================

types_path = File.join(__dir__, "..", "schema", "types")

require File.join(types_path, "base_object.rb")
require File.join(types_path, "pdf_response_type.rb")
require File.join(types_path, "producto_type.rb")  # Cargar producto antes de detalle y farmacia
require File.join(types_path, "detalle_type.rb")
require File.join(types_path, "farmacia_type.rb")
require File.join(types_path, "receta_type.rb")
require File.join(types_path, "paciente_type.rb")

# Eliminar posibles definiciones duplicadas en schema/Types (mayúsculas) para evitar conflictos en Windows
dup_path = File.join(__dir__, "..", "schema", "Types", "receta_type.rb")
if File.exist?(dup_path)
	begin
		# Evitar cargarlo; si ya se cargó accidentalmente antes, redefinir limpia (no hace falta aquí porque la versión correcta ya está cargada)
		puts "⚠️ Detectado archivo duplicado en schema/Types/receta_type.rb. Se recomienda eliminarlo para evitar conflictos."
	rescue => e
		puts "Error manejando duplicado RecetaType: #{e.message}"
	end
end
require File.join(types_path, "paciente_input_type.rb")
require File.join(types_path, "medico_input_type.rb")
require File.join(types_path, "query_type.rb")
require File.join(types_path, "mutation_type.rb")

puts "✅ Tipos requeridos: QueryType=#{defined?(Types::QueryType)} MutationType=#{defined?(Types::MutationType)}"

# =============================================
# 🔹 Luego cargar el schema principal
# =============================================
require File.join(__dir__, "..", "schema", "salumedx_schema.rb")
