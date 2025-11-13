module Types
  class PrescripcionDetalleInput < GraphQL::Schema::InputObject
    description "Campos requeridos para crear un detalle de prescripción"
    argument :detalleReceta, ID, required: true
    argument :farmacia, ID, required: true
    argument :producto, ID, required: true
    argument :precioEncontrado, Float, required: true
    argument :distancia, Float, required: true
    argument :fuente, String, required: true
  end
end