module MCP
  class BuscarFarmaciaCercana
    def self.execute(params, token, context = {})
      # Obtener parámetros
      user_lat = params[:user_lat] || params['user_lat'] || context[:user_lat]
      user_lng = params[:user_lng] || params['user_lng'] || context[:user_lng]
      producto_nombre = params[:producto] || params['producto']
      limit = (params[:limit] || params['limit'] || 5).to_i
      
      # Validar coordenadas
      unless user_lat && user_lng
        return {
          tool: 'buscar_farmacia_cercana',
          success: false,
          error: 'Se requiere la ubicación del usuario (user_lat, user_lng). Por favor, comparte tu ubicación.'
        }
      end
      
      puts "📍 Buscando farmacias cercanas a [#{user_lat}, #{user_lng}]"
      puts "   Producto: #{producto_nombre || 'todos'}" if producto_nombre
      
      # Llamar al servicio de farmacias
      service = FarmaciaService.new(token: token)
      farmacias = service.buscar_cercanas(
        user_lat, 
        user_lng, 
        producto_nombre: producto_nombre,
        limit: limit
      )
      
      if farmacias.empty?
        mensaje = producto_nombre ? 
          "No se encontraron farmacias con #{producto_nombre} disponible." :
          "No se encontraron farmacias cercanas."
        
        return {
          tool: 'buscar_farmacia_cercana',
          success: true,
          data: [],
          message: mensaje
        }
      end
      
      # Formatear resultado
      {
        tool: 'buscar_farmacia_cercana',
        success: true,
        data: farmacias,
        count: farmacias.size,
        user_location: {
          lat: user_lat,
          lng: user_lng
        }
      }
      
    rescue StandardError => e
      puts "❌ Error buscando farmacias cercanas: #{e.message}"
      puts e.backtrace.first(3)
      
      {
        tool: 'buscar_farmacia_cercana',
        success: false,
        error: e.message
      }
    end
  end
end
