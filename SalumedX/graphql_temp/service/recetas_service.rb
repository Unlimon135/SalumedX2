require 'json'

class RecetasResolver
  def initialize(rest_service)
    @rest = rest_service
  end

  # =====================
  # LISTAR TODAS LAS RECETAS
  # =====================
  def listar
    resp = @rest.get("/recetas/")
    raise "Error REST #{resp.code}" unless resp.code.to_i == 200

    data = JSON.parse(resp.body)

    data["recetas"].map { |r| RecetaModel.new(r) }
  end

  # =====================
  # OBTENER UNA SOLA RECETA POR ID
  # =====================
  def por_id(id)
    resp = @rest.get("/recetas/?id=#{id}")
    raise "Error REST #{resp.code}" unless resp.code.to_i == 200

    data = JSON.parse(resp.body)
    receta = data["recetas"].first

    RecetaModel.new(receta)
  end

  # =====================
  # CREAR UNA RECETA (POST)
  # =====================
  def crear(payload)
    resp = @rest.post_json("/recetas/", payload)
    code = resp.code.to_i
    unless code.between?(200, 299)
      body = resp.body.to_s
      begin
        j = JSON.parse(body)
        detail = j['detail'] || j['message'] || j['error'] || j.to_s[0,200]
      rescue
        detail = body[0,200]
      end
      raise "Error REST #{code}: #{detail}"
    end
    data = JSON.parse(resp.body) rescue {}
    data["receta"] || data["data"] || data
  end
end
