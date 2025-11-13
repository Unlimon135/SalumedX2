require_relative './config/environment'

require 'sinatra'
require 'json'
require 'graphql'
require 'rack/cors'
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
  end

  # ✅ Endpoints para páginas HTML
  get '/' do
    content_type 'text/html'
    File.read(File.join(settings.public_folder, 'app.html'))
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
