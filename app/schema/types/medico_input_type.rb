module Types
  class MedicoInputType < GraphQL::Schema::InputObject
    description "Datos de entrada para un médico"
    
    argument :nombre, String, required: true
    argument :numero_licencia, String, required: false
    argument :licencia, String, required: false
    argument :email, String, required: false
    argument :telefono, String, required: false
    argument :institucion, String, required: false
    argument :ubicacion_consultorio, String, required: false
  end
end
