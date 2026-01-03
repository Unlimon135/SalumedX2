class Settings
  class << self
    def port
      ENV['PORT'] || 5000
    end

    def llm_provider
      ENV['LLM_PROVIDER'] || 'gemini'
    end

    def gemini_api_key
      ENV['GEMINI_API_KEY']
    end

    def openai_api_key
      ENV['OPENAI_API_KEY']
    end

    def graphql_url
      ENV['GRAPHQL_SERVICE_URL'] || 'http://localhost:4000/graphql'
    end

    def rest_api_url
      ENV['REST_API_URL'] || 'https://salumedx-rest.onrender.com'
    end

    def jwt_secret
      ENV['JWT_SECRET']
    end

    def model_temperature
      ENV['MODEL_TEMPERATURE']&.to_f || 0.7
    end

    def max_tokens
      ENV['MAX_TOKENS']&.to_i || 2048
    end
  end
end
