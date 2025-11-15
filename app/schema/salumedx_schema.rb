# schema/salumedx_schema.rb
require 'batch-loader'

# Los tipos se cargan desde config/environment.rb
# No hacer require_relative aquí para evitar carga duplicada

class SalumedxSchema < GraphQL::Schema
  use BatchLoader::GraphQL
  
  rescue_from(StandardError) do |err|
    GraphQL::ExecutionError.new("Error interno del servidor: #{err.message}")
  end
end

# Configurar los tipos raíz DESPUÉS de que la clase esté definida
SalumedxSchema.query(Types::QueryType)
SalumedxSchema.mutation(Types::MutationType)

# Registrar tipos que no están directamente conectados desde Query/Mutation
SalumedxSchema.orphan_types(Types::DetalleType)