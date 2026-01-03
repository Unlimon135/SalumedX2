class LLMFactory
  def self.create(provider = nil)
    provider ||= Settings.llm_provider

    case provider.to_s.downcase
    when 'gemini'
      GeminiAdapter.new
    when 'openai'
      # OpenAIAdapter.new  # TODO: Implementar si es necesario
      raise "OpenAI adapter no implementado aún"
    else
      raise "Provider '#{provider}' no soportado"
    end
  end
end
