class MCPRouter
  def initialize(token: nil)
    @token = token
    @tools = register_tools
  end

  def execute(tool_name, params)
    tool = @tools[tool_name.to_sym]
    raise "Herramienta '#{tool_name}' no encontrada" unless tool
    
    puts "🔧 Ejecutando herramienta: #{tool_name}"
    
    # Algunas herramientas aceptan un tercer parámetro context
    begin
      tool.call(params, @token)
    rescue ArgumentError
      # Si la herramienta acepta 3 argumentos, pasar params vacío como context
      tool.call(params, @token, {})
    end
  end

  def list_tools
    @tools.keys
  end

  private

  def register_tools
    {
      # Queries
      buscar_producto: ->(params, token) { MCP::BuscarProducto.execute(params, token) },
      ver_receta: ->(params, token) { MCP::VerReceta.execute(params, token) },
      buscar_farmacia_cercana: ->(params, token, context = {}) { MCP::BuscarFarmaciaCercana.execute(params, token, context) },
      
      # Actions
      crear_receta: ->(params, token) { MCP::CrearReceta.execute(params, token) },
      actualizar_stock: ->(params, token) { MCP::ActualizarStock.execute(params, token) },
      
      # Reports
      resumen_ventas: ->(params, token) { MCP::ResumenVentas.execute(params, token) }
    }
  end
end
