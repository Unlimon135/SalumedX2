require 'httparty'

class GeminiAdapter < LLMAdapter
  API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'
  
  def initialize
    @api_key = Settings.gemini_api_key
    raise 'GEMINI_API_KEY no configurado' unless @api_key
    
    @model = 'gemini-2.5-flash'  # Modelo actualizado 2026
    @temperature = Settings.model_temperature
    @max_tokens = Settings.max_tokens
  end

  def generate_response(prompt)
    puts "🧠 Llamando a Gemini API..."
    puts "📝 Prompt length: #{prompt.length} caracteres"
    
    begin
      response = HTTParty.post(
        "#{API_URL}/#{@model}:generateContent?key=#{@api_key}",
        headers: { 'Content-Type' => 'application/json' },
        body: {
          contents: [{
            parts: [{ text: prompt }]
          }],
          generationConfig: {
            temperature: @temperature,
            maxOutputTokens: @max_tokens
          }
        }.to_json,
        timeout: 30
      )

      puts "📡 Status: #{response.code}"
      
      if response.success?
        text = extract_text(response)
        puts "✅ Respuesta obtenida de Gemini"
        return text
      elsif response.code == 429
        # Cuota excedida - extraer tiempo de espera
        error_data = JSON.parse(response.body) rescue {}
        error_msg = error_data.dig('error', 'message') || response.body
        
        # Intentar extraer tiempo de retry
        retry_match = error_msg.match(/retry in ([\d.]+)s/)
        retry_time = retry_match ? retry_match[1].to_f.ceil : 60
        
        puts "❌ Cuota de Gemini excedida. Retry en: #{retry_time}s"
        
        # Retornar mensaje amigable en lugar de error
        return <<~MSG
          Lo siento, el servicio de IA está temporalmente sobrecargado debido al alto uso. 
          
          🕒 Por favor, intenta de nuevo en aproximadamente #{retry_time} segundos.
          
          Si el problema persiste, el sistema puede estar en período de espera por límite de cuota gratuita.
        MSG
      else
        error_body = response.body[0..500]
        puts "❌ Error HTTP #{response.code}"
        puts "📄 Body: #{error_body}"
        raise "Error Gemini API: #{response.code} - #{error_body}"
      end
    rescue HTTParty::Error, Timeout::Error => e
      puts "❌ Error de conexión: #{e.message}"
      raise "Error conectando con Gemini: #{e.message}"
    end
  end

  def generate_with_tools(prompt, tools)
    # Gemini soporta function calling
    puts "🧠 Llamando a Gemini con herramientas..."
    
    response = HTTParty.post(
      "#{API_URL}/#{@model}:generateContent?key=#{@api_key}",
      headers: { 'Content-Type' => 'application/json' },
      body: {
        contents: [{
          parts: [{ text: prompt }]
        }],
        tools: format_tools(tools),
        generationConfig: {
          temperature: @temperature,
          maxOutputTokens: @max_tokens
        }
      }.to_json
    )

    if response.success?
      extract_text(response)
    else
      raise "Error Gemini API: #{response.code} - #{response.body}"
    end
  end

  def stream_response(prompt)
    # TODO: Implementar streaming
    generate_response(prompt)
  end

  private

  def extract_text(response)
    begin
      data = JSON.parse(response.body)
      
      # Debug: Mostrar estructura de respuesta
      puts "📦 Respuesta de Gemini recibida"
      
      if data['candidates'] && data['candidates'].any?
        candidate = data['candidates'].first
        
        # Verificar si hay contenido bloqueado
        if candidate['finishReason'] == 'SAFETY'
          return "Lo siento, no puedo generar una respuesta para esto debido a restricciones de seguridad."
        end
        
        parts = candidate.dig('content', 'parts')
        
        if parts && parts.any?
          text = parts.first['text']
          if text && !text.empty?
            puts "✅ Texto extraído: #{text[0..100]}..."
            return text.strip
          end
        end
      end
      
      # Si llegamos aquí, no hay texto válido
      puts "⚠️ No se encontró texto en la respuesta"
      puts "📄 Respuesta completa: #{data.inspect}"
      raise "No se pudo extraer texto de la respuesta de Gemini"
      
    rescue JSON::ParserError => e
      puts "❌ Error parseando JSON: #{e.message}"
      puts "📄 Body: #{response.body[0..500]}"
      raise "Error parseando respuesta de Gemini: #{e.message}"
    end
  end

  def format_tools(tools)
    # Formato de herramientas para Gemini Function Calling
    tools.map do |tool|
      {
        function_declarations: [{
          name: tool[:name],
          description: tool[:description],
          parameters: tool[:parameters]
        }]
      }
    end
  end
end
