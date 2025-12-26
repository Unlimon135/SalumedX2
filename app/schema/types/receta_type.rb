# app/schema/types/receta_type.rb
module Types
  class RecetaType < GraphQL::Schema::Object
    description "Representa una receta médica emitida por un médico a un paciente"

    field :id, ID, null: false
    field :fecha_emision, String, null: true
    field :diagnostico, String, null: true
    field :observaciones, String, null: true
    field :ubicacion_emision, String, null: true
    field :paciente_id, ID, null: true
    field :medico_id, ID, null: true
    # Array de detalles de prescripción (lazy loading para evitar problemas de orden)
    field :detalles, ["Types::DetalleType"], null: true

    # Resolvers para normalizar campos
    def id
      object['id_receta'] || object['id'] || object['receta_id'] || object['prescripcion_id']
    end

    def fecha_emision
      object['fecha_emision'] || object['fechaEmision'] || object['fecha'] || object['created_at']
    end

    def diagnostico
      object['diagnostico'] || object['diagnosis']
    end

    def observaciones
      object['observaciones'] || object['obs']
    end

    def ubicacion_emision
      object['ubicacion_emision'] || object['ubicacionEmision'] || object['ubicacion']
    end

    def paciente_id
      if object['paciente'].is_a?(Hash)
        object['paciente']['id']
      else
        object['paciente_id'] || object['pacienteId'] || object['paciente']
      end
    end

    def medico_id
      if object['medico'].is_a?(Hash)
        object['medico']['id']
      else
        object['medico_id'] || object['medicoId'] || object['medico']
      end
    end

    def detalles
      src = object['detalles'] || object['detalle'] || object['items'] || []
      Array(src)
    end
  end
end
