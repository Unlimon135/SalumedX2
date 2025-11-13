module Types
  class PacienteInputType < GraphQL::Schema::InputObject
    description "Datos del paciente para generar la receta PDF"

    argument :nombre, String, required: true
    argument :cedula, String, required: true
  end
end
