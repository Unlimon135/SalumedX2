# service/rest_service.rb
require 'httparty'

class RestService
  include HTTParty

  attr_reader :base_url, :auth, :cookies, :csrf_token, :bearer_token, :authorization_header

  def initialize(base_url, auth: nil, cookies: nil, csrf_token: nil, bearer_token: nil, authorization_header: nil)
    @base_url = base_url
    @auth = auth
    @cookies = cookies
    @csrf_token = csrf_token
    @bearer_token = bearer_token
    @authorization_header = authorization_header
  end

  # ========================
  # PETICIÓN GET
  # ========================
  def get(path)
    self.class.get(
      "#{base_url}#{path}",
      headers: build_headers_json
    )
  end

  # ========================
  # PETICIÓN POST JSON
  # ========================
  def post_json(path, body)
    self.class.post(
      "#{base_url}#{path}",
      body: body.to_json,
      headers: build_headers_json
    )
  end

  # ========================
  # PETICIÓN POST FORM (Django login)
  # ========================
  def post_form(path, form_data)
    self.class.post(
      "#{base_url}#{path}",
      body: form_data,
      headers: build_headers_form
    )
  end

  private

  # ------------------------
  # HEADERS PARA JSON
  # ------------------------
  def build_headers_json
    h = {
      "Content-Type" => "application/json",
      "Accept"       => "application/json"
    }
    
    # Preferencia: auth objeto, luego bearer, luego cookies+csrf
    if auth
      h.merge!(auth.auth_headers)
    end
    # If a raw Authorization header is provided, use it verbatim
    if authorization_header && !authorization_header.strip.empty?
      h["Authorization"] = authorization_header
    elsif bearer_token
      h["Authorization"] = "Bearer #{bearer_token}"
    end
    if cookies
      h["Cookie"] = cookies
    end
    if csrf_token
      h["X-CSRFToken"] = csrf_token
    end
    
    h
  end

  # ------------------------
  # HEADERS PARA FORM
  # ------------------------
  def build_headers_form
    h = {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept"       => "*/*",
      "Referer"      => "#{base_url}/api-auth/login/"
    }
    
    if auth
      h.merge!(auth.auth_headers)
    end
    if authorization_header && !authorization_header.strip.empty?
      h["Authorization"] = authorization_header
    elsif bearer_token
      h["Authorization"] = "Bearer #{bearer_token}"
    end
    if cookies
      h["Cookie"] = cookies
    end
    if csrf_token
      h["X-CSRFToken"] = csrf_token
    end
    
    h
  end
end
