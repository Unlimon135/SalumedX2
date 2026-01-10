class PromptBuilder
  def self.build_simple(message, context)
    system_prompt = context[:system_prompt]
    user_context = context[:user_context] || {}
    username = user_context[:username] || 'Usuario'
    role = user_context[:role]&.to_s&.downcase || 'paciente'
    
    # Sugerencias específicas por rol
    suggestions = get_role_suggestions(role)
    
    <<~PROMPT
      #{system_prompt}
      
      Usuario (#{username}): #{message}
      
      Instrucciones para la respuesta:
      - Sé amigable y profesional
      - Llama al usuario por su nombre (#{username})
      - Ten en cuenta que es un #{role}
      #{suggestions}
      
      Asistente:
    PROMPT
  end

  def self.build_with_tools(message, tool_results, context)
    system_prompt = context[:system_prompt]
    user_context = context[:user_context] || {}
    username = user_context[:username] || 'Usuario'
    role = user_context[:role]&.to_s&.downcase || 'paciente'
    
    # Formatear resultados de herramientas
    tools_info = format_tool_results(tool_results, role, username)
    
    <<~PROMPT
      #{system_prompt}
      
      Usuario (#{username}): #{message}
      
      Información obtenida de las herramientas del sistema:
      #{tools_info}
      
      Instrucciones para la respuesta:
      - Presenta la información de manera clara y organizada
      - Llama al usuario por su nombre (#{username})
      - Si hay errores de permisos, explícalos con empatía
      - Ofrece alternativas útiles
      - Si hay datos numéricos, preséntalos en formato de lista o tabla
      - Usa emojis apropiados para mejorar la legibilidad
      
      Asistente:
    PROMPT
  end

  def self.build_function_calling(message, tools, context)
    system_prompt = context[:system_prompt]
    
    tools_list = tools.map do |tool|
      "- #{tool[:name]}: #{tool[:description]}"
    end.join("\n")
    
    <<~PROMPT
      #{system_prompt}
      
      Herramientas disponibles:
      #{tools_list}
      
      Usuario: #{message}
      
      ¿Qué herramientas necesitas usar para responder? Responde en formato JSON:
      { "tools": ["tool_name1", "tool_name2"], "params": {...} }
      
      Asistente:
    PROMPT
  end
  
  private
  
  def self.get_role_suggestions(role)
    case role
    when 'medico', 'doctor'
      "- Puedes ayudarle a crear recetas médicas
- Puede consultar información de pacientes
- Tiene acceso completo a funciones médicas"
    when 'farmaceutico', 'farmacia'
      "- Puedes ayudarle con gestión de inventario
- Puede ver reportes de ventas
- Puede dispensar medicamentos"
    when 'paciente'
      "- Puede consultar sus recetas
- Puede buscar medicamentos
- Puede encontrar farmacias cercanas
- NO puede crear recetas (solo médicos)"
    when 'admin', 'administrador'
      "- Tiene acceso completo a todas las funcionalidades
- Puede gestionar usuarios y permisos"
    else
      "- Ofrece ayuda general del sistema"
    end
  end
  
  def self.format_tool_results(tool_results, role, username)
    formatted = []
    
    tool_results.each do |tool_name, result|
      # Manejar errores de permisos
      if tool_name.to_s.include?('error_permiso')
        formatted << "❌ #{result[:error]}"
        formatted << "💡 #{result[:suggestion]}" if result[:suggestion]
        next
      end
      
      # Formatear según el tipo de herramienta
      case tool_name.to_s
      when 'buscar_producto'
        if result[:success] && result[:data]
          count = result[:count] || result[:data].size
          formatted << "🔍 Búsqueda de productos: #{count} resultados encontrados"
          formatted << "Datos: #{result[:data].to_json}"
        else
          formatted << "⚠️ No se encontraron productos"
        end
        
      when 'buscar_farmacia_cercana'
        if result[:success] && result[:data]&.any?
          formatted << "📍 Farmacias cercanas a #{username}:"
          formatted << "Se encontraron #{result[:count]} farmacias"
          formatted << "Datos: #{result[:data].to_json}"
        elsif result[:error]
          formatted << "⚠️ #{result[:error]}"
        end
        
      when 'ver_receta'
        if result[:success]
          formatted << "📋 Receta consultada exitosamente"
          formatted << "Datos: #{result[:data].to_json}"
        else
          formatted << "⚠️ #{result[:error] || 'No se pudo consultar la receta'}"
        end
        
      when 'crear_receta'
        if result[:success]
          formatted << "✅ Receta creada exitosamente por Dr. #{username}"
          formatted << "Datos: #{result[:data].to_json}"
        else
          formatted << "❌ #{result[:error] || 'Error al crear receta'}"
        end
        
      when 'actualizar_stock'
        if result[:success]
          formatted << "✅ Inventario actualizado por #{username}"
          formatted << "Datos: #{result[:data].to_json}"
        else
          formatted << "❌ #{result[:error] || 'Error al actualizar inventario'}"
        end
        
      when 'resumen_ventas'
        if result[:success]
          formatted << "📊 Reporte de ventas generado"
          formatted << "Datos: #{result[:data].to_json}"
        else
          formatted << "❌ #{result[:error] || 'Error al generar reporte'}"
        end
        
      else
        # Formato genérico
        formatted << "#{tool_name}: #{result.to_json}"
      end
    end
    
    formatted.join("\n")
  end
end
