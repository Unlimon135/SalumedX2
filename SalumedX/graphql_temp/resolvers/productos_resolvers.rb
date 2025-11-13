# resolvers/productos_resolver.rb
require 'json'
require 'cgi'

class ProductoResolver
  def initialize(rest_service)
    @rest = rest_service
  end

  # Busca productos por nombre desde el servicio REST de Django
  def buscar_productos(nombre:)
    raise ArgumentError, "El nombre del producto no puede estar vacío" if nombre.nil? || nombre.strip.empty?

    # Endpoint real del backend Django
    path = "/productos/?nombre=#{CGI.escape(nombre)}"
    response = @rest.get(path)
    data = parse_json!(response)

    data.map do |p|
      {
        id:            p['id'],
        nombre:        p['nombre'],
        precio:        p['precio'],
        presentacion:  p['presentacion'],
        stock:         p['stock'],
        farmacia_id:   p['farmacia_id']
      }
    end
  rescue StandardError => e
    raise GraphQL::ExecutionError, "Error obteniendo productos: #{e.message}"
  end

  private

  def parse_json!(response)
    raise "Sin respuesta del REST" unless response
    code = response.code.to_i rescue 200
    raise "Error REST #{code}" unless code.between?(200, 299)
    JSON.parse(response.body.to_s)
  end
end

