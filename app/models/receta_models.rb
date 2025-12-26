# models/receta.rb
class RecetaModel
  attr_accessor :id, :fecha_emision, :paciente_id, :medico_id, :observaciones, :detalles

  def initialize(data)
    data ||= {}

    # Mapear ID desde posibles claves utilizadas por el REST
    @id = data['id'] || data['receta_id'] || data['pk'] || data['uuid'] || (data['receta'] && data['receta']['id'])
    @id = @id.to_s if @id

    # Campos comunes con alternativas de nombre
    @fecha_emision  = data['fecha_emision'] || data['fechaEmision'] || data['fecha'] || "Sin fecha"
    @paciente_id    = data['paciente_id'] || data['pacienteId'] || (data['paciente'] && data['paciente']['id'])
    @medico_id      = data['medico_id']   || data['medicoId']   || (data['medico'] && data['medico']['id'])
    @observaciones  = data['observaciones'] || data['obs'] || "Sin observaciones"

    detalles_src = data['detalles'] || data['detalle'] || data['items'] || []
    @detalles = Array(detalles_src).map { |d| DetallePrescripcionModel.new(d) rescue nil }.compact
  end
end
