class FarmaciaModel
  attr_accessor :id, :nombre, :direccion, :lat, :lng, :distancia_km, :productos

  def initialize(data)
    @id            = data['id']
    @nombre        = data['nombre'] || "Sin nombre"
    @direccion     = data['direccion'] || "Dirección no especificada"
    @lat           = data['lat'] || data['latitude'] || 0.0
    @lng           = data['lng'] || data['longitude'] || 0.0
    @distancia_km  = data['distancia_km'] || 0.0
    @productos     = data['productos'] || []
  end
end
