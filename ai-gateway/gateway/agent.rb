class Agent
  attr_reader :llm, :mcp_router, :context, :token, :user_context

  def initialize(token: nil, context: {})
    @token = token
    @user_context = context  # Contexto del usuario (ubicación, etc.)
    @llm = LLMFactory.create
    @mcp_router = MCPRouter.new(token: token)
    @context = ContextBuilder.new(context)  # Pasar contexto al builder
  end

  def process_message(message)
    puts "🤖 Procesando mensaje: #{message}"
    
    begin
      # Construir contexto
      context_data = @context.build(message)
      puts "✅ Contexto construido"
      
      # Determinar si necesita ejecutar herramientas MCP
      tools_needed = detect_tools_needed(message)
      puts "🔍 Herramientas detectadas: #{tools_needed.any? ? tools_needed.join(', ') : 'ninguna'}"
      
      if tools_needed.any?
        # Ejecutar herramientas MCP
        tool_results = execute_tools(tools_needed, message)
        puts "✅ Herramientas ejecutadas"
        
        # Generar respuesta con contexto de herramientas
        prompt = PromptBuilder.build_with_tools(message, tool_results, context_data)
        response = @llm.generate_response(prompt)
        
        unless response && !response.empty?
          raise "Respuesta vacía del LLM"
        end
        
        puts "✅ Respuesta generada (#{response.length} caracteres)"
        
        {
          response: response,
          tools_used: tools_needed,
          data: tool_results
        }
      else
        # Respuesta directa sin herramientas
        prompt = PromptBuilder.build_simple(message, context_data)
        response = @llm.generate_response(prompt)
        
        unless response && !response.empty?
          raise "Respuesta vacía del LLM"
        end
        
        puts "✅ Respuesta generada (#{response.length} caracteres)"
        
        {
          response: response,
          tools_used: []
        }
      end
    rescue StandardError => e
      puts "❌ Error en process_message: #{e.message}"
      puts e.backtrace.first(5)
      
      username = @user_context[:username] || 'Usuario'
      
      # Mensaje de fallback más amigable
      fallback_message = if e.message.include?('429')
        "#{username}, el servicio de IA está temporalmente sobrecargado. Por favor, intenta de nuevo en unos minutos. 🕒"
      elsif e.message.include?('timeout') || e.message.include?('Timeout')
        "#{username}, la conexión con el servicio de IA está tardando demasiado. Por favor, intenta de nuevo. ⏱️"
      elsif e.message.include?('API') || e.message.include?('Gemini')
        "Lo siento #{username}, hay un problema temporal con el servicio de IA. Por favor, intenta de nuevo más tarde. 🔧"
      else
        "Lo siento #{username}, ocurrió un error al procesar tu mensaje. Por favor intenta de nuevo. ❌"
      end
      
      # Retornar respuesta de error
      {
        response: fallback_message,
        tools_used: [],
        error: e.message
      }
    end
  end

  private

  def detect_tools_needed(message)
    tools = []
    user_role = @user_context[:role]&.to_s&.downcase || 'paciente'
    
    puts "🔍 Detectando herramientas para rol: #{user_role}"
    
    # Detección simple por palabras clave
    tools << 'buscar_producto' if message.match?(/buscar|producto|medicamento/i)
    
    # Ver recetas (todos pueden ver)
    tools << 'ver_receta' if message.match?(/ver|consultar|mostrar.*receta|receta.*\d+/i)
    
    # Crear receta (SOLO médicos)
    if message.match?(/crear|generar|nueva.*receta|prescribir|recetar/i)
      if ['medico', 'doctor'].include?(user_role)
        tools << 'crear_receta'
      else
        tools << 'error_permiso_receta'
      end
    end
    
    # Actualizar stock (SOLO farmacéuticos y admin)
    if message.match?(/stock|inventario|actualizar|modificar/i)
      if ['farmaceutico', 'farmacia', 'admin', 'administrador'].include?(user_role)
        tools << 'actualizar_stock'
      else
        tools << 'error_permiso_stock'
      end
    end
    
    # Reportes de ventas (SOLO farmacéuticos y admin)
    if message.match?(/ventas|reporte|resumen|estadísticas|analítica/i)
      if ['farmaceutico', 'farmacia', 'admin', 'administrador', 'medico'].include?(user_role)
        tools << 'resumen_ventas'
      else
        tools << 'error_permiso_reportes'
      end
    end
    
    # Farmacias cercanas (todos, pero necesita ubicación)
    if message.match?(/farmacia|botica|cerca|cercana|dónde|donde|ubicación|ubicacion|comprar/i)
      tools << 'buscar_farmacia_cercana'
    end
    
    puts "✅ Herramientas detectadas: #{tools.join(', ')}"
    tools
  end

  def execute_tools(tools, message)
    results = {}
    user_role = @user_context[:role]&.to_s&.downcase || 'paciente'
    username = @user_context[:username] || 'Usuario'
    
    tools.each do |tool_name|
      begin
        # Manejar errores de permisos
        case tool_name
        when 'error_permiso_receta'
          results[tool_name] = {
            tool: 'crear_receta',
            success: false,
            error: "Lo siento #{username}, solo los médicos pueden crear recetas. Tu rol actual es: #{user_role}.",
            suggestion: "Puedes consultar tus recetas existentes o buscar medicamentos disponibles."
          }
          next
        when 'error_permiso_stock'
          results[tool_name] = {
            tool: 'actualizar_stock',
            success: false,
            error: "#{username}, no tienes permisos para gestionar el inventario. Esta función está disponible solo para farmacéuticos.",
            suggestion: "Puedes buscar productos disponibles o consultar información sobre medicamentos."
          }
          next
        when 'error_permiso_reportes'
          results[tool_name] = {
            tool: 'resumen_ventas',
            success: false,
            error: "#{username}, no tienes acceso a los reportes de ventas. Esta función está disponible para personal autorizado.",
            suggestion: "¿Puedo ayudarte con algo más? Puedo buscar medicamentos o farmacias cercanas."
          }
          next
        end
        
        params = extract_params(tool_name, message)
        
        # Pasar contexto de usuario a las herramientas
        if ['buscar_farmacia_cercana', 'crear_receta', 'ver_receta'].include?(tool_name)
          params.merge!(@user_context)
        end
        
        result = @mcp_router.execute(tool_name, params)
        results[tool_name] = result
        
      rescue StandardError => e
        puts "⚠️ Error ejecutando #{tool_name}: #{e.message}"
        results[tool_name] = { 
          tool: tool_name,
          success: false,
          error: e.message 
        }
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
    when 'buscar_farmacia_cercana'
      # Extraer nombre de producto si se menciona
      producto_match = message.match(/(\w+)\s+en\s+farmacia|farmacia.*(?:con|tiene|vende)\s+(\w+)/i)
      params = {}
      if producto_match
        params[:producto] = (producto_match[1] || producto_match[2]).strip
      end
      params
    else
      {}
    end
  end
end
