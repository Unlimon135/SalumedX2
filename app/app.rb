require_relative './config/environment'

require 'sinatra'
require 'json'
require 'graphql'
require 'rack/cors'
require 'net/http'
require 'uri'
require_relative './config/server_config'
require_relative './service/rest_service'
require_relative './schema/salumedx_schema'
require_relative './service/django_session_auth'

class GraphqlService < Sinatra::Base
  configure do
    set :port, ServerConfig.port
    set :bind, ServerConfig.bind_address
    set :environment, ServerConfig.environment
    set :public_folder, File.join(settings.root, 'public')

    use Rack::Cors do
      allow do
        # Para cookies, no se puede usar '*', debe ser el origen específico
        origins 'http://localhost:4000', 'http://127.0.0.1:4000'
        resource '*', 
          headers: :any, 
          methods: [:get, :post, :options],
          credentials: true, # Permitir cookies y credenciales
          expose: ['X-CSRFToken']
      end
    end
  end

  # ✅ LOGIN AUTOMÁTICO ANTES DE CUALQUIER REQUEST
  # Comentado para permitir autenticación desde el frontend
  # before do
  #   DjangoSessionAuth.admin.login!    if DjangoSessionAuth.admin.csrf.nil?
  #   DjangoSessionAuth.medico.login!   if DjangoSessionAuth.medico.csrf.nil?
  #   DjangoSessionAuth.paciente.login! if DjangoSessionAuth.paciente.csrf.nil?
  # end

  # Nuevo: Extraer cookies y CSRF token del frontend
  helpers do
    def get_user_cookies
      cookies_header = request.env['HTTP_COOKIE'] || ''
      csrf_token = request.env['HTTP_X_CSRFTOKEN'] || ''
      authorization = request.env['HTTP_AUTHORIZATION'] || ''
      
      {
        cookies: cookies_header,
        csrf_token: csrf_token,
        authorization: authorization
      }
    end

    # ✅ Reenviar notificación al servidor WebSocket
    def forward_notification_to_websocket(type, data)
      begin
        uri = URI('http://localhost:8080/api/notifications')
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 2
        
        request = Net::HTTP::Post.new(uri.path)
        request['Content-Type'] = 'application/json'
        request.body = {
          type: type,
          data: data,
          timestamp: Time.now.to_i
        }.to_json
        
        response = http.request(request)
        if response.code.to_i == 200
          ServerConfig.logger.info("✅ Notificación reenviada al WebSocket: #{type}")
        else
          ServerConfig.logger.warn("⚠️ WebSocket no respondió correctamente: #{response.code}")
        end
      rescue StandardError => e
        ServerConfig.logger.warn("⚠️ No se pudo conectar al WebSocket (¿está corriendo?): #{e.message}")
        # No es crítico si el WebSocket no está disponible
      end
    end
  end

  # ✅ Endpoints para páginas HTML
  get '/' do
    content_type 'text/html'
    File.read(File.join(settings.public_folder, 'app.html'))
  end

  # ✅ Endpoint para servir el dashboard de notificaciones
  get '/dashboard' do
    content_type 'text/html'
    dashboard_path = File.join(
      settings.root, 
      'websocket_service/websocket_web2/src/client.html'
    )
    if File.exist?(dashboard_path)
      File.read(dashboard_path)
    else
      status 404
      "Dashboard no encontrado en #{dashboard_path}"
    end
  end

  # ✅ Endpoint para recibir notificaciones y reenviarlas al WebSocket
  post '/api/notifications' do
    begin
      body = request.body.read
      payload = body.empty? ? {} : JSON.parse(body)
      
      type = payload['type']
      data = payload['data']
      timestamp = payload['timestamp'] || Time.now.to_i
      user = payload['user']
      
      ServerConfig.logger.info("📨 Notificación recibida: #{type}")
      ServerConfig.logger.info("   Data: #{data.inspect}")
      
      # ✅ Reenviar al servidor WebSocket en background (no bloqueante)
      Thread.new do
        forward_notification_to_websocket(type, data)
      end
      
      content_type :json
      { 
        message: 'Notificación recibida correctamente',
        type: type,
        timestamp: timestamp
      }.to_json
    rescue StandardError => e
      ServerConfig.logger.error("❌ Error procesando notificación: #{e.message}")
      status 400
      { error: e.message }.to_json
    end
  end



  # ✅ GraphQL real
  post '/graphql' do
    body = request.body.read
    payload = body.empty? ? {} : JSON.parse(body)

    query = payload['query']
    variables = payload['variables'] || {}
    operation_name = payload['operationName']

    # Obtener cookies y CSRF del usuario actual (frontend)
    user_auth = get_user_cookies
    
    # Crear un RestService con la autenticación del usuario
    # que viene desde el navegador (cookies + CSRF)
    user_rest_service = RestService.new(
      ServerConfig.rest_api_url,
      cookies: user_auth[:cookies],
      csrf_token: user_auth[:csrf_token],
      authorization_header: user_auth[:authorization]
    )

    # Inyectamos el servicio REST autenticado con las credenciales del usuario
    context = {
      rest_user: user_rest_service
      # Los clientes admin/medico/paciente se mantienen disponibles como fallback
      # pero solo se inicializan si son necesarios
      # rest_admin:    RestService.new(ServerConfig.rest_api_url, auth: DjangoSessionAuth.admin),
      # rest_medico:   RestService.new(ServerConfig.rest_api_url, auth: DjangoSessionAuth.medico),
      # rest_paciente: RestService.new(ServerConfig.rest_api_url, auth: DjangoSessionAuth.paciente)
    }

    result = SalumedxSchema.execute(
      query,
      variables: variables,
      context: context,
      operation_name: operation_name
    )

    content_type :json
    result.to_json
  rescue StandardError => e
    ServerConfig.logger.error(e.message)
    status 500
    { errors: [{ message: e.message }] }.to_json
  end

  get '/health' do
    content_type :json
    { status: 'ok', service: 'GraphQL', config: ServerConfig.summary }.to_json
  end
end

GraphqlService.run! if __FILE__ == $PROGRAM_NAME
