class Agent
  attr_reader :llm, :mcp_router, :context, :token

  def initialize(token: nil)
    @token = token
    @llm = LLMFactory.create
    @mcp_router = MCPRouter.new(token: token)
    @context = ContextBuilder.new
  end

  def process_message(message)
    puts "🤖 Procesando mensaje: #{message}"
    
    # Construir contexto
    context_data = @context.build(message)
    
    # Determinar si necesita ejecutar herramientas MCP
    tools_needed = detect_tools_needed(message)
    
    if tools_needed.any?
      # Ejecutar herramientas MCP
      tool_results = execute_tools(tools_needed, message)
      
      # Generar respuesta con contexto de herramientas
      prompt = PromptBuilder.build_with_tools(message, tool_results, context_data)
      response = @llm.generate_response(prompt)
      
      {
        response: response,
        tools_used: tools_needed,
        data: tool_results
      }
    else
      # Respuesta directa sin herramientas
      prompt = PromptBuilder.build_simple(message, context_data)
      response = @llm.generate_response(prompt)
      
      {
        response: response,
        tools_used: []
      }
    end
  end

  private

  def detect_tools_needed(message)
    tools = []
    
    # Detección simple por palabras clave
    tools << 'buscar_producto' if message.match?(/buscar|producto|medicamento/i)
    tools << 'ver_receta' if message.match?(/receta|prescripción/i)
    tools << 'crear_receta' if message.match?(/crear|generar|nueva receta/i)
    tools << 'actualizar_stock' if message.match?(/stock|inventario|actualizar/i)
    tools << 'resumen_ventas' if message.match?(/ventas|reporte|resumen|estadísticas/i)
    
    tools
  end

  def execute_tools(tools, message)
    results = {}
    
    tools.each do |tool_name|
      begin
        result = @mcp_router.execute(tool_name, extract_params(tool_name, message))
        results[tool_name] = result
      rescue StandardError => e
        puts "⚠️ Error ejecutando #{tool_name}: #{e.message}"
        results[tool_name] = { error: e.message }
      end
    end
    
    results
  end

  def extract_params(tool_name, message)
    # Extracción simple de parámetros del mensaje
    # En producción usar NLP o mejor parsing
    case tool_name
    when 'buscar_producto'
      # Extraer nombre del producto
      { nombre: message.gsub(/buscar|producto|medicamento/i, '').strip }
    when 'ver_receta'
      # Extraer ID de receta
      match = message.match(/receta\s+(\d+)/i)
      { receta_id: match ? match[1].to_i : nil }
    when 'resumen_ventas'
      # Fechas por defecto: último mes
      { fecha_inicio: (Date.today - 30).to_s, fecha_fin: Date.today.to_s }
    else
      {}
    end
  end
end
