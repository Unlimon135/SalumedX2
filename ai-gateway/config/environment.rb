require 'sinatra/base'
require 'sinatra/json'
require 'dotenv/load'
require 'json'
require 'httparty'
require 'rack/cors'

# Cargar configuración
require_relative './settings'

# Utils
require_relative '../utils/prompt_builder'
require_relative '../utils/file_parser'

# Infraestructura
require_relative '../infra/http_client'
require_relative '../infra/db'

# Inicializar base de datos
DB.instance
puts "✅ Base de datos SQLite inicializada"

# LLM Adapters
require_relative '../llm/llm_adapter'
require_relative '../llm/gemini_adapter'
require_relative '../llm/llm_factory'

# Services
require_relative '../services/product_service'
require_relative '../services/receta_service'
require_relative '../services/report_service'
require_relative '../services/farmacia_service'

# MCP Tools
require_relative '../mcp/queries/buscar_producto'
require_relative '../mcp/queries/ver_receta'
require_relative '../mcp/queries/buscar_farmacia_cercana'
require_relative '../mcp/actions/crear_receta'
require_relative '../mcp/actions/actualizar_stock'
require_relative '../mcp/reports/resumen_ventas'

# Gateway
require_relative '../gateway/context_builder'
require_relative '../gateway/mcp_router'
require_relative '../gateway/agent'

# Controllers
require_relative '../controllers/chat_controller'

puts "✅ AI Gateway inicializado"
puts "   LLM Provider: #{Settings.llm_provider}"
puts "   Puerto: #{ENV['PORT'] || 5000}"
