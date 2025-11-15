require 'json'
require 'cgi'

class ProductosService
  def initialize(rest_service)
    @rest = rest_service
  end

  # Calcula la factura total de una lista de productos
  def calcular_factura(productos)
    raise ArgumentError, 'La lista de productos está vacía' if productos.nil? || productos.empty?

    total = productos.sum do |prod|
      precio = obtener_precio_producto(prod[:producto_id], prod[:farmacia_id])
      precio.to_f * (prod[:cantidad] || 1)
    end

    {
      subtotal: total.round(2),
      iva: (total * 0.15).round(2),
      total: (total * 1.15).round(2)
    }
  end

  # Compara los precios de un producto en distintas farmacias
  def comparar_precios(nombre_producto)
    raise ArgumentError, 'El nombre del producto es obligatorio' if nombre_producto.nil? || nombre_producto.strip.empty?

    datos = buscar_productos_por_nombre(nombre_producto)
    datos.map do |p|
      {
        id: p['id'],
        nombre: p['nombre'],
        precio: p['precio'],
        farmacia_id: p['farmacia_id'],
        farmacia_nombre: p.dig('farmacia', 'nombre')
      }
    end.sort_by { |r| r[:precio].to_f }
  end

  private

  # --- Llamadas REST ---

  # Obtiene el precio de un producto específico (si existe endpoint por ID)
  def obtener_precio_producto(producto_id, farmacia_id)
    # Si el  REST tiene /productos/{id}/, usa esa ruta
    path = "/productos/#{producto_id}/"
    res = @rest.get(path)
    data = parse_json!(res)
    data['precio'] || 0
  rescue
    0
  end

  # Busca productos por nombre en el endpoint real de Django
  def buscar_productos_por_nombre(nombre)
    path = "/productos/?nombre=#{CGI.escape(nombre)}"
    parse_json!(@rest.get(path))
  end

  # --- Util ---
  def parse_json!(response)
    raise "Sin respuesta del REST" unless response
    code = response.code.to_i rescue 200
    raise "Error REST #{code}" unless code.between?(200, 299)
    JSON.parse(response.body.to_s)
  end
end
