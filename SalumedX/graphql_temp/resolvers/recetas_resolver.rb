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
    raise "No autorizado (403)" if resp.code.to_i == 403
    raise "Error REST #{resp.code}" unless resp.code.to_i == 200

    data = JSON.parse(resp.body) rescue {}
    items = data["recetas"] || data["results"] || data
    items = Array(items)
    recetas = items.map { |r| RecetaModel.new(r) }
    # Evitar errores GraphQL: no devolver recetas sin ID
    recetas.reject { |r| r.id.nil? }
  end

  # =====================
  # OBTENER UNA SOLA RECETA POR ID
  # =====================
  def por_id(id)
    resp = @rest.get("/recetas/?id=#{id}")
    raise "No autorizado (403)" if resp.code.to_i == 403
    raise "Error REST #{resp.code}" unless resp.code.to_i == 200

    data = JSON.parse(resp.body) rescue {}
    receta = (data["recetas"] || data["results"] || []).first
    return nil unless receta
    model = RecetaModel.new(receta)
    return nil if model.id.nil?
    model
  end

  # =====================
  # CREAR UNA RECETA (POST)
  # =====================
  def crear(payload)
    # Usar el endpoint de detalle-prescripcion para crear recetas
    resp = @rest.post_json("/detalle-prescripcion/", payload)
    code = resp.code.to_i
    if code == 403
      body = resp.body.to_s
      raise "No autorizado (403) - #{body[0,200]}"
    end
    unless code.between?(200, 299)
      body = resp.body.to_s
      # intenta extraer detalle del error
      begin
        j = JSON.parse(body)
        detail = j['detail'] || j['message'] || j['error'] || j.to_s[0,200]
      rescue
        detail = body[0,200]
      end
      raise "Error REST #{code}: #{detail}"
    end

    data = JSON.parse(resp.body) rescue {}
    # La API puede devolver {"receta": {...}} o el objeto plano
    receta = data["receta"] || data["data"] || data
    receta
  end
end
