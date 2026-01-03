module MCP
  class ActualizarStock
    def self.execute(params, token)
      producto_id = params[:producto_id] || params['producto_id']
      cantidad = params[:cantidad] || params['cantidad']
      
      raise "Parámetros 'producto_id' y 'cantidad' requeridos" unless producto_id && cantidad
      
      puts "📦 Actualizando stock del producto #{producto_id}: #{cantidad}"
      
      # Llamar al servicio de productos
      service = ProductService.new(token: token)
      resultado = service.actualizar_stock(producto_id, cantidad)
      
      {
        tool: 'actualizar_stock',
        success: true,
        data: resultado,
        message: 'Stock actualizado exitosamente'
      }
    rescue StandardError => e
      {
        tool: 'actualizar_stock',
        success: false,
        error: e.message
      }
    end
  end
end
