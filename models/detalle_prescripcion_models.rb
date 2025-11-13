# models/detalle_prescripcion.rb
class DetallePrescripcionModel
  attr_accessor :id, :receta_id, :producto_id, :producto_nombre, :dosis, :frecuencia, :duracion, :indicaciones

  def initialize(data)
    @id               = data['id']
    @receta_id        = data['receta_id']
    @producto_id      = data['producto_id']
    @producto_nombre  = data['producto_nombre'] || data['producto'] || "Desconocido"
    @dosis            = data['dosis'] || "No especificada"
    @frecuencia       = data['frecuencia'] || "No especificada"
    @duracion         = data['duracion'] || "No especificada"
    @indicaciones     = data['indicaciones'] || "Sin indicaciones adicionales"
  end
end
