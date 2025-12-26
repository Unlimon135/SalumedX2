require 'json'

class DetalleService
  def initialize(rest_service)
    @rest = rest_service
  end

  def obtener_detalles_por_receta(receta_id)
    path = "/detalle-prescripcion/?receta_id=#{receta_id}"
    res = @rest.get(path)
    parse_json!(res)
  end

  private

  def parse_json!(res)
    raise "Sin respuesta del REST" unless res
    code = res.code.to_i rescue 200
    raise "Error REST #{code}" unless code.between?(200, 299)
    JSON.parse(res.body.to_s)
  end
end
