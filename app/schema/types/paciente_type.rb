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

    # Resolvers para normalizar campos
    def id
      object['id'] || object['paciente_id'] || object['pk']
    end

    def nombre
      if object['user'].is_a?(Hash)
        first_name = object['user']['first_name'] || ''
        last_name = object['user']['last_name'] || ''
        "#{first_name} #{last_name}".strip
      else
        object['nombre'] || object['nombre_completo']
      end
    end

    def cedula
      object['cedula'] || object['ci']
    end

    def email
      if object['user'].is_a?(Hash)
        object['user']['email']
      else
        object['email']
      end
    end

    def telefono
      object['telefono'] || object['phone']
    end

    def direccion
      object['direccion'] || object['address']
    end

    def fecha_nacimiento
      object['fecha_nacimiento'] || object['fechaNacimiento'] || object['birth_date']
    end

    def usuario_id
      if object['user'].is_a?(Hash)
        object['user']['id']
      else
        object['usuario_id'] || object['user_id'] || object['user']
      end
    end
  end
end
