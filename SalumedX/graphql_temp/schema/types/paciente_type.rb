module Types
  class PacienteType < Types::BaseObject
    description "Representa un paciente registrado en el sistema"

    field :id, ID, null: false, description: "ID del paciente"
    field :nombre, String, null: true, description: "Nombre completo del paciente"
    field :cedula, String, null: true, description: "Cédula de identidad"
    field :email, String, null: true, description: "Email del paciente"
    field :telefono, String, null: true, description: "Teléfono de contacto"
    field :direccion, String, null: true, description: "Dirección"
    field :fecha_nacimiento, String, null: true, description: "Fecha de nacimiento"
    field :usuario_id, ID, null: true, description: "ID del usuario asociado"
  end
end
