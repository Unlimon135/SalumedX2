# resolvers/farmacia_resolver.rb
require 'batch-loader'
require 'json'
require 'cgi'

class FarmaciaResolver
  def initialize(rest_service)
    @rest = rest_service
  end

  # Obtiene farmacias cercanas (usa lat, lng, radio, limit)
  def farmacias_cercanas(lat:, lng:, radio:, producto: nil, limit: 10)
    # 1️⃣ Obtener lista de farmacias
    farmacias = get_farmacias(lat: lat, lng: lng, radio: radio, limit: limit)

    # 2️⃣ Mapear datos y asociar productos (si existen)
    farmacias.map do |f|
      {
        id: f['id'],
        nombre: f['nombre'],
        direccion: f['direccion'],
        lat: f['lat'] || f['latitude'],
        lng: f['lng'] || f['longitude'],
        distancia_km: f['distancia_km'],
        productos: BatchLoader.for(f['id']).batch do |farmacia_ids, loader|
          farmacia_ids.each do |fid|
            productos = get_productos_por_farmacia(fid, producto)
            loader.call(fid, productos)
          end
        end
      }
    end
  rescue StandardError => e
    raise GraphQL::ExecutionError, "Error al obtener farmacias: #{e.message}"
  end

  private

  # ---- Llamadas REST ----

  def get_farmacias(lat:, lng:, radio:, limit:)
    # Si tu endpoint acepta parámetros geográficos, se pueden incluir.
    # Pero si no los maneja aún, simplemente obtiene todas las farmacias.
    path = "/farmacias/?limit=#{limit}"
    parse_json!(@rest.get(path))
  end

  def get_productos_por_farmacia(farmacia_id, filtro = nil)
    query = filtro && !filtro.strip.empty? ? "&nombre=#{CGI.escape(filtro)}" : ""
    path = "/productos/?farmacia_id=#{farmacia_id}#{query}"
    parse_json!(@rest.get(path))
  rescue StandardError
    []
  end

  # ---- Utilidad ----
  def parse_json!(response)
    raise "Sin respuesta del REST" unless response
    code = response.code.to_i rescue 200
    raise "Error REST #{code}" unless code.between?(200, 299)
    JSON.parse(response.body.to_s)
  end
end
