module MCP
  class BuscarProducto
    def self.execute(params, token)
      nombre = params[:nombre] || params['nombre']
      
      raise "Parámetro 'nombre' requerido" unless nombre
      
      puts "🔍 Buscando producto: #{nombre}"
      
      # Llamar al servicio de productos
      service = ProductService.new(token: token)
      productos = service.buscar(nombre)
      
      {
        tool: 'buscar_producto',
        success: true,
        data: productos,
        count: productos.size
      }
    rescue StandardError => e
      {
        tool: 'buscar_producto',
        success: false,
        error: e.message
      }
    end
  end
end
