# app/service/auth_proxy.rb
require 'httparty'

class AuthProxy
  include HTTParty

  base_uri ENV['AUTH_SERVICE_URL'] || 'http://localhost:3001'

  # ✅ Login - obtener access y refresh tokens
  def self.login(username:, password:)
    response = post(
      '/auth/login',
      body: { username: username, password: password }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      {
        success: true,
        access_token: response['access'] || response['access_token'],
        refresh_token: response['refresh'] || response['refresh_token'],
        user: response['user']
      }
    else
      {
        success: false,
        error: response['message'] || 'Login falló'
      }
    end
  rescue StandardError => e
    { success: false, error: "Error conectando al Auth Service: #{e.message}" }
  end

  # ✅ Registro - crear nuevo usuario
  def self.register(username:, email:, password:, role: 'user')
    response = post(
      '/auth/register',
      body: {
        username: username,
        email: email,
        password: password,
        role: role
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      {
        success: true,
        user: response['user']
      }
    else
      {
        success: false,
        error: response['message'] || 'Registro falló'
      }
    end
  rescue StandardError => e
    { success: false, error: "Error conectando al Auth Service: #{e.message}" }
  end

  # ✅ Logout - revocar tokens
  def self.logout(access_token:, refresh_token:)
    response = post(
      '/auth/logout',
      body: { refresh: refresh_token }.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}"
      }
    )

    if response.success?
      { success: true, message: 'Logout exitoso' }
    else
      { success: false, error: response['message'] || 'Logout falló' }
    end
  rescue StandardError => e
    { success: false, error: "Error conectando al Auth Service: #{e.message}" }
  end

  # ✅ Refresh - obtener nuevo access token
  def self.refresh(refresh_token:)
    response = post(
      '/auth/refresh',
      body: { refresh: refresh_token }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      {
        success: true,
        access_token: response['access'] || response['access_token'],
        refresh_token: response['refresh'] || refresh_token
      }
    else
      { success: false, error: response['message'] || 'Refresh falló' }
    end
  rescue StandardError => e
    { success: false, error: "Error conectando al Auth Service: #{e.message}" }
  end

  # ✅ Validate - verificar token contra el Auth Service (para revocación)
  def self.validate(access_token:)
    response = post(
      '/auth/validate',
      body: { token: access_token }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      {
        success: true,
        data: response.parsed_response
      }
    else
      {
        success: false,
        error: response.parsed_response && response.parsed_response['message'] || 'Token inválido'
      }
    end
  rescue StandardError => e
    { success: false, error: "Error validando token: #{e.message}" }
  end
end
