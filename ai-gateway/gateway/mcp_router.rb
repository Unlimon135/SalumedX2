class MCPRouter
  def initialize(token: nil)
    @token = token
    @tools = register_tools
  end

  def execute(tool_name, params)
    tool = @tools[tool_name.to_sym]
    raise "Herramienta '#{tool_name}' no encontrada" unless tool
    
    puts "🔧 Ejecutando herramienta: #{tool_name}"
    tool.call(params, @token)
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
      
      # Actions
      crear_receta: ->(params, token) { MCP::CrearReceta.execute(params, token) },
      actualizar_stock: ->(params, token) { MCP::ActualizarStock.execute(params, token) },
      
      # Reports
      resumen_ventas: ->(params, token) { MCP::ResumenVentas.execute(params, token) }
    }
  end
end
