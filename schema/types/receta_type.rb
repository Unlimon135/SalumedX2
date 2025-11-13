module Types
  class RecetaType < Types::BaseObject
    description "Representa una receta médica (prescripción)"

    field :id, ID, null: false, description: "Identificador de la receta"
    field :fecha_emision, String, null: true, description: "Fecha de emisión"
    field :paciente_id, ID, null: true, description: "ID del paciente asociado"
    field :medico_id, ID, null: true, description: "ID del médico que emitió la receta"
    field :observaciones, String, null: true, description: "Observaciones generales"
    field :detalles, [Types::DetalleType], null: true, description: "Lista de detalles (productos) incluidos en la receta"

    # Normalizar distintos nombres de campo que puede devolver el backend REST
    def fecha_emision
      object['fecha_emision'] || object['fechaEmision'] || object['fecha']
    end

    def paciente_id
      object['paciente_id'] || object['pacienteId'] || (object['paciente'] && object['paciente']['id'])
    end

    def medico_id
      object['medico_id'] || object['medicoId'] || (object['medico'] && object['medico']['id'])
    end

    def observaciones
      object['observaciones'] || object['obs']
    end

    def detalles
      src = object['detalles'] || object['detalle'] || object['items'] || []
      Array(src)
    end
  end
end