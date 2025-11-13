module Types
  class MedicoInputType < GraphQL::Schema::InputObject
    description "Datos del médico para generar la receta PDF"

    argument :nombre, String, required: true
    argument :licencia, String, required: true
  end
end
