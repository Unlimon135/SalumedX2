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
    recetas_array = data["recetas"] || data["results"] || []
    
    # Mapear las recetas del formato del API al formato esperado por GraphQL
    recetas_array.map do |r|
      {
        'id' => r['id_receta'],
        'id_receta' => r['id_receta'],
        'fecha_emision' => r['fecha_emision'],
        'diagnostico' => r['diagnostico'],
        'observaciones' => r['observaciones'],
        'ubicacion_emision' => r['ubicacion_emision'],
        'paciente_id' => r['paciente'] ? r['paciente']['id'] : nil,
        'medico_id' => r['medico'] ? r['medico']['id'] : nil,
        'paciente' => r['paciente'],
        'medico' => r['medico'],
        'detalles' => (r['detalles'] || []).map { |d| mapear_detalle(d) }
      }
    end
  end

  # =====================
  # OBTENER UNA SOLA RECETA POR ID
  # =====================
  def por_id(id)
    resp = @rest.get("/recetas/#{id}/")
    raise "No autorizado (403)" if resp.code.to_i == 403
    raise "Error REST #{resp.code}" unless resp.code.to_i == 200

    data = JSON.parse(resp.body) rescue {}
    return nil unless data && data['id_receta']
    
    {
      'id' => data['id_receta'],
      'id_receta' => data['id_receta'],
      'fecha_emision' => data['fecha_emision'],
      'diagnostico' => data['diagnostico'],
      'observaciones' => data['observaciones'],
      'ubicacion_emision' => data['ubicacion_emision'],
      'paciente_id' => data['paciente'] ? data['paciente']['id'] : nil,
      'medico_id' => data['medico'] ? data['medico']['id'] : nil,
      'paciente' => data['paciente'],
      'medico' => data['medico'],
      'detalles' => (data['detalles'] || []).map { |d| mapear_detalle(d) }
    }
  end

  # =====================
  # CREAR UNA RECETA (POST)
  # =====================
  def crear(payload)
    resp = @rest.post_json("/recetas/", payload)
    code = resp.code.to_i
    if code == 403
      body = resp.body.to_s
      raise "No autorizado (403) - #{body[0,200]}"
    end
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
    receta = data["receta"] || data["data"] || data
    
    {
      'id' => receta['id_receta'],
      'id_receta' => receta['id_receta'],
      'fecha_emision' => receta['fecha_emision'],
      'diagnostico' => receta['diagnostico'],
      'observaciones' => receta['observaciones'],
      'ubicacion_emision' => receta['ubicacion_emision'],
      'paciente_id' => receta['paciente'] ? receta['paciente']['id'] : receta['paciente'],
      'medico_id' => receta['medico'] ? receta['medico']['id'] : receta['medico'],
      'detalles' => (receta['detalles'] || []).map { |d| mapear_detalle(d) }
    }
  end

  private

  # Mapear detalle de receta del formato API al formato GraphQL
  def mapear_detalle(detalle)
    {
      'id' => detalle['id_detalle_receta'],
      'id_detalle_receta' => detalle['id_detalle_receta'],
      'producto_id' => detalle['producto'] ? (detalle['producto']['id_producto'] || detalle['producto']) : nil,
      'producto' => detalle['producto'],
      'cantidad' => detalle['cantidad'],
      'dosis' => detalle['dosis'],
      'presentacion' => detalle['presentacion'],
      'duracion_tratamiento' => detalle['duracion_tratamiento'],
      'instrucciones' => detalle['instrucciones'],
      'indicaciones' => detalle['instrucciones'] # alias
    }
  end
end
