# app/service/jwt_validator.rb
require 'jwt'
require 'httparty'

class JwtValidator
  include HTTParty
  
  # URL del microservicio de autenticación de tu compañero
  AUTH_SERVICE_URL = ENV['AUTH_SERVICE_URL'] || 'http://localhost:3001'
  
  # Secret compartido para validar JWTs (debe coincidir con el Auth Service)
  JWT_SECRET = ENV['JWT_SECRET'] || 'tu_secret_compartido_aqui'
  JWT_ALGORITHM = 'HS256'
  
  # ✅ Validar token localmente (SIN llamar al Auth Service)
  def self.validate_token(token)
    return { valid: false, error: 'Token no proporcionado' } if token.nil? || token.empty?
    
    begin
      # Extraer "Bearer " del header si viene
      token = token.gsub(/^Bearer /, '')
      
      # Decodificar y validar JWT localmente
      decoded = JWT.decode(token, JWT_SECRET, true, { algorithm: JWT_ALGORITHM })
      payload = decoded.first
      
      # Verificar expiración
      exp = payload['exp']
      return { valid: false, error: 'Token expirado' } if exp && Time.now.to_i > exp
      
      # Validación remota opcional (para revocación) si se activa el flag
      if ENV['AUTH_REMOTE_VALIDATE'] == 'true'
        remote = remote_validate(token)
        return { valid: false, error: remote[:error] || 'Token inválido' } unless remote[:valid]

        # Si el servicio devuelve datos del usuario, usarlos
        payload = remote[:payload] if remote[:payload]
      end
      
      # Token válido
      {
        valid: true,
        user_id: payload['user_id'],
        username: payload['username'],
        role: payload['role'],
        email: payload['email']
      }
      
    rescue JWT::DecodeError => e
      { valid: false, error: "Token inválido: #{e.message}" }
    rescue JWT::ExpiredSignature
      { valid: false, error: 'Token expirado' }
    rescue StandardError => e
      { valid: false, error: "Error validando token: #{e.message}" }
    end
  end
  
  # ✅ Obtener user info del Auth Service (solo cuando sea necesario)
  def self.get_user_info(token)
    begin
      response = get(
        "#{AUTH_SERVICE_URL}/auth/me",
        headers: { 'Authorization' => "Bearer #{token}" }
      )
      
      if response.success?
        response.parsed_response
      else
        nil
      end
    rescue StandardError => e
      puts "⚠️ Error obteniendo info de usuario: #{e.message}"
      nil
    end
  end
  
  # ✅ Validación remota (revocación/estado) opcional
  def self.remote_validate(token)
    response = post(
      "#{AUTH_SERVICE_URL}/auth/validate",
      body: { token: token }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      data = response.parsed_response
      {
        valid: true,
        payload: data['user'] || data
      }
    else
      {
        valid: false,
        error: response.parsed_response && response.parsed_response['message'] || 'Token inválido'
      }
    end
  rescue StandardError => e
    { valid: false, error: "Error validando token remotamente: #{e.message}" }
  end
end
