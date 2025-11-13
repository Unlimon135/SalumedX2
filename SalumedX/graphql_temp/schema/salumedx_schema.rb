# schema/salumedx_schema.rb
require 'batch-loader'

# clase para definir el esquema de GraphQL
=begin
La clase SalumedxSchema en Ruby hereda de GraphQL::Schema.
Define el tipo de consulta principal (query type) 
que permite realizar las operaciones GraphQL de la aplicación y utiliza BatchLoader::GraphQL para optimizar la carga de datos, 
evitando consultas repetidas o innecesarias.
=end

class SalumedxSchema < GraphQL::Schema
  use BatchLoader::GraphQL

  rescue_from(StandardError) do |err|
    GraphQL::ExecutionError.new("Error interno del servidor: #{err.message}")
  end
end

# Cargar los tipos DESPUÉS de definir la clase base
require_relative 'types/base_object'
require_relative 'types/pdf_response_type'
require_relative 'types/detalle_type'
require_relative 'types/farmacia_type'
require_relative 'types/producto_type'
require_relative 'types/receta_type'
require_relative 'types/paciente_input_type'
require_relative 'types/medico_input_type'
require_relative 'types/prescripcion_detalle_input_type'
require_relative 'types/query_type'
require_relative 'types/mutation_type'

# Asignar los tipos raíz DESPUÉS de que se hayan cargado
SalumedxSchema.query(Types::QueryType)
SalumedxSchema.mutation(Types::MutationType)