class ContextBuilder
  def initialize
    @context_history = []
  end

  def build(message)
    # Agregar mensaje al historial
    @context_history << {
      role: 'user',
      content: message,
      timestamp: Time.now
    }

    # Mantener solo últimos 10 mensajes
    @context_history = @context_history.last(10)

    # Construir contexto del sistema
    {
      system_prompt: system_prompt,
      history: @context_history,
      timestamp: Time.now
    }
  end

  def add_response(response)
    @context_history << {
      role: 'assistant',
      content: response,
      timestamp: Time.now
    }
  end

  private

  def system_prompt
    <<~PROMPT
      Eres un asistente médico inteligente para el sistema SaluMedX.
      
      Puedes ayudar con:
      - Buscar productos y medicamentos
      - Ver recetas médicas
      - Crear nuevas recetas (solo si el usuario es médico)
      - Consultar inventario
      - Generar reportes de ventas
      
      Responde de manera clara, profesional y empática.
      Si no tienes información suficiente, pregunta por más detalles.
      Si necesitas ejecutar una acción, indícalo claramente.
    PROMPT
  end
end
