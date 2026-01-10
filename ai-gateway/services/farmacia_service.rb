class FarmaciaService
  EARTH_RADIUS_KM = 6371

  def initialize(token: nil)
    @token = token
    @http = HTTPClient.new
  end

  # Buscar farmacias y calcular distancia desde ubicación del usuario
  def buscar_cercanas(user_lat, user_lng, producto_nombre: nil, limit: 5)
    # Obtener todas las farmacias desde GraphQL
    farmacias = obtener_farmacias()
    
    # Si se especifica un producto, filtrar farmacias que lo tengan
    if producto_nombre
      farmacias = filtrar_por_producto(farmacias, producto_nombre)
    end
    
    # Calcular distancia desde la ubicación del usuario
    farmacias_con_distancia = farmacias.map do |farmacia|
      farmacia_lat = farmacia['lat'] || farmacia['latitude'] || 0.0
      farmacia_lng = farmacia['lng'] || farmacia['longitude'] || 0.0
      
      distancia = calcular_distancia(
        user_lat.to_f, user_lng.to_f,
        farmacia_lat.to_f, farmacia_lng.to_f
      )
      
      farmacia.merge('distancia_km' => distancia.round(2))
    end
    
    # Ordenar por distancia y limitar resultados
    farmacias_con_distancia
      .sort_by { |f| f['distancia_km'] }
      .first(limit)
  end

  private

  # Obtener farmacias desde GraphQL
  def obtener_farmacias
    query = <<~GRAPHQL
      query {
        farmacias {
          id
          nombre
          direccion
          lat
          lng
          productos {
            id
            nombreGenerico
            nombreComercial
            precio
            stock
          }
        }
      }
    GRAPHQL

    response = @http.graphql_request(query, {}, @token)
    
    if response['data'] && response['data']['farmacias']
      response['data']['farmacias']
    else
      []
    end
  end

  # Filtrar farmacias que tengan el producto buscado
  def filtrar_por_producto(farmacias, producto_nombre)
    nombre_lower = producto_nombre.downcase
    
    farmacias.select do |farmacia|
      productos = farmacia['productos'] || []
      productos.any? do |producto|
        generico = (producto['nombreGenerico'] || '').downcase
        comercial = (producto['nombreComercial'] || '').downcase
        generico.include?(nombre_lower) || comercial.include?(nombre_lower)
      end
    end
  end

  # Calcular distancia usando fórmula de Haversine
  # Retorna distancia en kilómetros
  def calcular_distancia(lat1, lng1, lat2, lng2)
    # Convertir grados a radianes
    lat1_rad = deg_to_rad(lat1)
    lat2_rad = deg_to_rad(lat2)
    delta_lat = deg_to_rad(lat2 - lat1)
    delta_lng = deg_to_rad(lng2 - lng1)

    # Fórmula de Haversine
    a = Math.sin(delta_lat / 2) ** 2 +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        Math.sin(delta_lng / 2) ** 2
    
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    
    # Distancia en kilómetros
    EARTH_RADIUS_KM * c
  end

  def deg_to_rad(degrees)
    degrees * Math::PI / 180
  end
end
