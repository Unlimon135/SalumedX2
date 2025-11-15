module Types
  class PrescripcionDetalleInputType < GraphQL::Schema::InputObject
    description "Detalle de un producto en una prescripción"
    
    argument :producto, ID, required: true, description: "ID del producto"
    argument :cantidad, Integer, required: true, description: "Cantidad del producto"
    argument :dosis, String, required: false, description: "Dosis del medicamento"
    argument :presentacion, String, required: false, description: "Presentación del producto"
    argument :duracion_tratamiento, String, required: false, description: "Duración del tratamiento"
    argument :instrucciones, String, required: false, description: "Instrucciones de uso"
  end
end
