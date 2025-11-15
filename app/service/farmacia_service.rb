# service/farmacia_service.rb
require 'json'
require 'cgi'

class FarmaciaService
  def initialize(rest_service)
    @rest = rest_service
  end

  # 🔹 Listar todas las farmacias o buscar por nombre
  def listar_farmacias(nombre: nil)
    path = '/farmacias/'
    path += "?nombre=#{CGI.escape(nombre)}" if nombre
    parse_json!(@rest.get(path))
  end

  # 🔹 Listar productos globalmente o filtrarlos por nombre
  def listar_productos(nombre: nil)
    path = '/productos/'
    path += "?nombre=#{CGI.escape(nombre)}" if nombre
    parse_json!(@rest.get(path))
  end

  # 🔹 Obtener productos específicos de una farmacia
  def productos_por_farmacia(farmacia_id)
    # Si tu API REST soporta filtro por farmacia_id:
    path = "/productos/?farmacia_id=#{farmacia_id}"
    parse_json!(@rest.get(path))
  end

  # 🔹 Recomendar farmacias con productos más baratos
  def recomendar_farmacias(nombre_producto: nil)
    farmacias = listar_farmacias
    return farmacias unless nombre_producto

    productos = listar_productos(nombre: nombre_producto)
    farmacias.map do |farmacia|
      productos_filtrados = productos.select { |p| p['farmacia_id'] == farmacia['id'] }
      precio_min = productos_filtrados.map { |p| p['precio'] }.compact.min

      {
        id: farmacia['id'],
        nombre: farmacia['nombre'],
        direccion: farmacia['direccion'],
        precio_minimo: precio_min
      }
    end.sort_by { |f| f[:precio_minimo] || Float::INFINITY }
  end

  private

  def parse_json!(response)
    raise "Sin respuesta del REST" unless response
    code = response.code.to_i rescue 200
    raise "Error REST #{code}" unless code.between?(200, 299)
    JSON.parse(response.body.to_s)
  end
end
