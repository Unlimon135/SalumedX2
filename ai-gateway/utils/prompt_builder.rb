class PromptBuilder
  def self.build_simple(message, context)
    system_prompt = context[:system_prompt]
    
    <<~PROMPT
      #{system_prompt}
      
      Usuario: #{message}
      
      Asistente:
    PROMPT
  end

  def self.build_with_tools(message, tool_results, context)
    system_prompt = context[:system_prompt]
    
    tools_info = tool_results.map do |tool_name, result|
      "- #{tool_name}: #{result.to_json}"
    end.join("\n")
    
    <<~PROMPT
      #{system_prompt}
      
      Usuario: #{message}
      
      Información obtenida de herramientas:
      #{tools_info}
      
      Con base en esta información, responde al usuario de manera clara y útil.
      
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
end
