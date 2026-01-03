require 'httparty'

class GeminiAdapter < LLMAdapter
  API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'
  
  def initialize
    @api_key = Settings.gemini_api_key
    raise 'GEMINI_API_KEY no configurado' unless @api_key
    
    @model = 'gemini-pro'
    @temperature = Settings.model_temperature
    @max_tokens = Settings.max_tokens
  end

  def generate_response(prompt)
    puts "🧠 Llamando a Gemini API..."
    
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
      }.to_json
    )

    if response.success?
      extract_text(response)
    else
      raise "Error Gemini API: #{response.code} - #{response.body}"
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
    data = JSON.parse(response.body)
    
    if data['candidates'] && data['candidates'].any?
      candidate = data['candidates'].first
      parts = candidate.dig('content', 'parts')
      
      if parts && parts.any?
        return parts.first['text']
      end
    end
    
    raise "No se pudo extraer texto de la respuesta: #{response.body}"
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
