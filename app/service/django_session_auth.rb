# app/auth/django_session_auth.rb
require 'httparty'

class DjangoSessionAuth
  include HTTParty
  format :html

  attr_reader :cookies, :csrf, :base_url

  LOGIN_PATH = "/api-auth/login/?next="

  def initialize(base_url:, username:, password:)
    @base_url = base_url
    @username = username
    @password = password
    @cookies = {}
    @csrf = nil
  end

  def self.admin
    @admin ||= DjangoSessionAuth.new(
      base_url: ENV["REST_API_URL"],
      username: ENV["ADMIN_USER"],
      password: ENV["ADMIN_PASS"]
    )
  end

  def self.medico
    @medico ||= DjangoSessionAuth.new(
      base_url: ENV["REST_API_URL"],
      username: ENV["MEDICO_USER"],
      password: ENV["MEDICO_PASS"]
    )
  end

  def self.paciente
    @paciente ||= DjangoSessionAuth.new(
      base_url: ENV["REST_API_URL"],
      username: ENV["PACIENTE_USER"],
      password: ENV["PACIENTE_PASS"]
    )
  end

  def fetch_csrf!
    resp = self.class.get("#{base_url}#{LOGIN_PATH}")
    header = resp.headers["set-cookie"].to_s

    @csrf = header[/csrftoken=([^;]+)/, 1]
    raise "No se pudo obtener csrftoken" unless @csrf

    @cookies.merge!(parse_cookies(header))
  end

  def login!
    fetch_csrf! if @csrf.nil?

    body = {
      "username" => @username,
      "password" => @password,
      "csrfmiddlewaretoken" => @csrf,
      "next" => "/"
    }

    headers = {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Cookie" => cookie_string,
      "Referer" => "#{base_url}#{LOGIN_PATH}"
    }

    resp = self.class.post("#{base_url}#{LOGIN_PATH}", body: body, headers: headers)

    raise "Login Django falló #{resp.code}" unless [200, 302].include?(resp.code)

    @cookies.merge!(parse_cookies(resp.headers["set-cookie"].to_s))
    return true
  end

  def auth_headers
    {
      "Cookie" => cookie_string,
      "X-CSRFToken" => @csrf
    }
  end

  private

  def parse_cookies(header)
    cookies = {}
    header.split(",").each do |segment|
      pair = segment.split(";").first
      k, v = pair.split("=")
      cookies[k] = v if k && v
    end
    cookies
  end

  def cookie_string
    @cookies.map { |k,v| "#{k}=#{v}" }.join("; ")
  end
end
