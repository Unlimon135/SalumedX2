# config/server_config.rb
require 'logger'
require 'dotenv/load'

module ServerConfig
  # Configuración general de la aplicación
  class << self
    # Puerto por defecto del servidor
    def port
      ENV.fetch('PORT', 4000).to_i
    end

    # Dirección donde escuchará el servidor
    def bind_address
      ENV.fetch('BIND_ADDRESS', '0.0.0.0')
    end

    # Entorno actual: development, test, production
    def environment
      ENV.fetch('RACK_ENV', 'development')
    end

    # URL del servicio REST (por defecto, API pública en Render)
    def rest_api_url
      ENV.fetch('REST_API_URL', 'https://salumedx-rest.onrender.com')
    end

    # Logger configurable
    def logger
      @logger ||= Logger.new($stdout, level: log_level)
    end

    # Nivel de logs según entorno
    def log_level
      case environment
      when 'development' then Logger::DEBUG
      when 'test' then Logger::WARN
      else Logger::INFO
      end
    end

    # Muestra configuración activa al iniciar
    def summary
      {
        port: port,
        bind_address: bind_address,
        environment: environment,
        rest_api_url: rest_api_url
      }
    end
  end
end
