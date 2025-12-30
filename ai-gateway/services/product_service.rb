class ProductService
  def initialize(token: nil)
    @token = token
    @http = HTTPClient.new
  end

  def buscar(nombre)
    query = <<~GRAPHQL
      query($nombre: String!) {
        productos(nombre: $nombre) {
          id
          nombreGenerico
          nombreComercial
          categoria
          precio
          stock
        }
      }
    GRAPHQL

    response = @http.graphql_request(query, { nombre: nombre }, @token)
    
    if response['data'] && response['data']['productos']
      response['data']['productos']
    else
      []
    end
  end

  def actualizar_stock(producto_id, cantidad)
    # Llamar a REST API Django
    response = @http.rest_request(
      "#{Settings.rest_api_url}/productos/#{producto_id}/stock/",
      method: :patch,
      body: { cantidad: cantidad },
      token: @token
    )
    
    response
  end
end
