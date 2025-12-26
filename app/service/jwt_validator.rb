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
  
  # Cache de tokens revocados (actualizar periódicamente)
  @blacklist_cache = []
  @last_blacklist_update = nil
  BLACKLIST_CACHE_TTL = 60 # 1 minuto
  
  class << self
    attr_accessor :blacklist_cache, :last_blacklist_update
  end
  
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
      
      # Verificar si está en blacklist
      if token_revoked?(token)
        return { valid: false, error: 'Token revocado' }
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
  
  # ✅ Verificar si token está revocado (con cache)
  def self.token_revoked?(token)
    update_blacklist_cache if cache_expired?
    @blacklist_cache.include?(token)
  end
  
  # ✅ Actualizar cache de blacklist desde Auth Service
  def self.update_blacklist_cache
    begin
      response = get("#{AUTH_SERVICE_URL}/auth/blacklist")
      if response.success?
        @blacklist_cache = response.parsed_response['tokens'] || []
        @last_blacklist_update = Time.now
      end
    rescue StandardError => e
      puts "⚠️ No se pudo actualizar blacklist: #{e.message}"
    end
  end
  
  # ✅ Verificar si cache expiró
  def self.cache_expired?
    @last_blacklist_update.nil? || 
    (Time.now - @last_blacklist_update) > BLACKLIST_CACHE_TTL
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
  
  # ✅ Refresh token (llamada al Auth Service)
  def self.refresh_token(refresh_token)
    begin
      response = post(
        "#{AUTH_SERVICE_URL}/auth/refresh",
        body: { refresh_token: refresh_token }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      if response.success?
        {
          access_token: response['access_token'],
          refresh_token: response['refresh_token']
        }
      else
        nil
      end
    rescue StandardError => e
      puts "⚠️ Error refrescando token: #{e.message}"
      nil
    end
  end
end
