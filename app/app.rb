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
require_relative './service/jwt_validator'
require_relative './service/auth_proxy'

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

    # ✅ Validar JWT y obtener usuario actual
    def current_user
      auth_header = request.env['HTTP_AUTHORIZATION']
      return nil unless auth_header
      
      result = JwtValidator.validate_token(auth_header)
      result[:valid] ? result : nil
    end
    
    # ✅ Requiere autenticación (usar en rutas protegidas)
    def require_auth!
      user = current_user
      unless user
        halt 401, { error: 'No autenticado o token inválido' }.to_json
      end
      user
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

    # ✅ Validar JWT del usuario actual
    auth_header = request.env['HTTP_AUTHORIZATION']
    user_info = nil
    
    if auth_header
      validation_result = JwtValidator.validate_token(auth_header)
      if validation_result[:valid]
        user_info = validation_result
        ServerConfig.logger.info("✅ Usuario autenticado: #{user_info[:username]} (#{user_info[:role]})")
      else
        ServerConfig.logger.warn("⚠️ Token inválido: #{validation_result[:error]}")
      end
    end

    # Obtener cookies y CSRF del usuario actual (fallback para compatibilidad con Django)
    user_auth = get_user_cookies
    
    # Crear un RestService con la autenticación del usuario
    user_rest_service = RestService.new(
      ServerConfig.rest_api_url,
      cookies: user_auth[:cookies],
      csrf_token: user_auth[:csrf_token],
      authorization_header: auth_header
    )

    # Inyectamos el servicio REST y la info del usuario JWT
    context = {
      rest_user: user_rest_service,
      current_user: user_info  # ← Info del JWT (user_id, username, role, email)
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

  # ========================================
  # 🔐 ENDPOINTS DE AUTENTICACIÓN (Proxy al Auth Service)
  # ========================================
  
  # ✅ Login - obtener tokens JWT
  post '/auth/login' do
    begin
      body = request.body.read
      payload = JSON.parse(body)
      
      result = AuthProxy.login(
        username: payload['username'],
        password: payload['password']
      )
      
      content_type :json
      if result[:success]
        status 200
        result.to_json
      else
        status 401
        { error: result[:error] }.to_json
      end
    rescue JSON::ParserError
      status 400
      { error: 'JSON inválido' }.to_json
    rescue StandardError => e
      status 500
      { error: e.message }.to_json
    end
  end
  
  # ✅ Registro - crear nuevo usuario
  post '/auth/register' do
    begin
      body = request.body.read
      payload = JSON.parse(body)
      
      result = AuthProxy.register(
        username: payload['username'],
        email: payload['email'],
        password: payload['password'],
        role: payload['role'] || 'user'
      )
      
      content_type :json
      if result[:success]
        status 201
        result.to_json
      else
        status 400
        { error: result[:error] }.to_json
      end
    rescue JSON::ParserError
      status 400
      { error: 'JSON inválido' }.to_json
    rescue StandardError => e
      status 500
      { error: e.message }.to_json
    end
  end
  
  # ✅ Logout - revocar tokens
  post '/auth/logout' do
    begin
      user = current_user
      unless user
        halt 401, { error: 'No autenticado' }.to_json
      end
      
      body = request.body.read
      payload = JSON.parse(body)
      
      result = AuthProxy.logout(
        access_token: request.env['HTTP_AUTHORIZATION'].gsub(/^Bearer /, ''),
        refresh_token: payload['refresh_token']
      )
      
      content_type :json
      if result[:success]
        status 200
        result.to_json
      else
        status 400
        { error: result[:error] }.to_json
      end
    rescue JSON::ParserError
      status 400
      { error: 'JSON inválido' }.to_json
    rescue StandardError => e
      status 500
      { error: e.message }.to_json
    end
  end
  
  # ✅ Refresh - obtener nuevo access token
  post '/auth/refresh' do
    begin
      body = request.body.read
      payload = JSON.parse(body)
      
      result = AuthProxy.refresh(
        refresh_token: payload['refresh_token']
      )
      
      content_type :json
      if result[:success]
        status 200
        result.to_json
      else
        status 401
        { error: result[:error] }.to_json
      end
    rescue JSON::ParserError
      status 400
      { error: 'JSON inválido' }.to_json
    rescue StandardError => e
      status 500
      { error: e.message }.to_json
    end
  end
  
  # ✅ Me - obtener info del usuario actual
  get '/auth/me' do
    user = current_user
    unless user
      halt 401, { error: 'No autenticado' }.to_json
    end
    
    content_type :json
    user.to_json
  end

  get '/health' do
    content_type :json
    { status: 'ok', service: 'GraphQL', config: ServerConfig.summary }.to_json
  end
end

GraphqlService.run! if __FILE__ == $PROGRAM_NAME
