require_relative './config/environment'

class AIGateway < Sinatra::Base
  configure do
    set :port, ENV['PORT'] || 5000
    set :bind, '0.0.0.0'
    set :environment, :production
    
    # CORS
    use Rack::Cors do
      allow do
        origins '*'
        resource '*', 
          headers: :any, 
          methods: [:get, :post, :options]
      end
    end
  end

  # Health check
  get '/health' do
    content_type :json
    { 
      status: 'ok', 
      service: 'AI Gateway',
      llm_provider: Settings.llm_provider
    }.to_json
  end

  # Chat endpoint
  post '/chat/message' do
    ChatController.handle_message(request, params)
  end

  # Procesar imagen
  post '/chat/image' do
    ChatController.handle_image(request, params)
  end

  # Procesar PDF
  post '/chat/pdf' do
    ChatController.handle_pdf(request, params)
  end

  # Historial
  get '/chat/history' do
    ChatController.get_history(request, params)
  end

  # Error handlers
  error 400 do
    content_type :json
    { error: 'Bad Request', message: env['sinatra.error'].message }.to_json
  end

  error 401 do
    content_type :json
    { error: 'Unauthorized', message: 'Token inválido o ausente' }.to_json
  end

  error 500 do
    content_type :json
    { error: 'Internal Server Error', message: env['sinatra.error'].message }.to_json
  end
end

AIGateway.run! if __FILE__ == $PROGRAM_NAME
