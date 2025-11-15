module Types
  class PacienteInputType < GraphQL::Schema::InputObject
    description "Datos de entrada para un paciente"
    
    argument :nombre, String, required: true
    argument :cedula, String, required: true
    argument :email, String, required: false
    argument :telefono, String, required: false
    argument :direccion, String, required: false
    argument :fecha_nacimiento, String, required: false
  end
end
