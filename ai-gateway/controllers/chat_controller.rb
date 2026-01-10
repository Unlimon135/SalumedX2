class ChatController
  class << self
    def handle_message(app, request, params)
      app.content_type :json
      
      begin
        # Obtener token JWT
        token = extract_token(request)
        
        # Parsear body
        body = JSON.parse(request.body.read)
        message = body['message']
        user_lat = body['user_lat']
        user_lng = body['user_lng']
        
        app.halt 400, { error: 'Mensaje requerido' }.to_json unless message
        
        puts "📥 Mensaje recibido: #{message[0..50]}..."
        
        # Guardar mensaje del usuario
        user_id = extract_user_id(token)
        if user_id
          DB.instance.save_message(user_id, message, 'user')
          puts "💾 Mensaje usuario guardado"
        end
        
        # Crear contexto con ubicación si está disponible
        context = {}
        if user_lat && user_lng
          context[:user_lat] = user_lat
          context[:user_lng] = user_lng
          puts "📍 Ubicación recibida: [#{user_lat}, #{user_lng}]"
        end
        
        # Agregar información del usuario al contexto
        if user_id && user_id != 'anonymous'
          context[:user_id] = user_id
          # Extraer más info del token si está disponible
          user_info = extract_user_info(token)
          context[:username] = user_info[:username] if user_info[:username]
          context[:role] = user_info[:role] if user_info[:role]
          puts "👤 Usuario: #{user_id} (#{user_info[:username] || 'sin nombre'})"
        end
        
        # Crear agente
        agent = Agent.new(token: token, context: context)
        
        # Procesar mensaje
        response = agent.process_message(message)
        
        puts "📤 Respuesta del agente recibida"
        
        # Validar respuesta
        unless response && response[:response]
          puts "⚠️ Respuesta vacía o inválida"
          response = {
            response: "Lo siento, no pude generar una respuesta. Por favor intenta de nuevo.",
            tools_used: [],
            error: "empty_response"
          }
        end
        
        # Guardar respuesta del asistente
        if user_id && response[:response]
          DB.instance.save_message(user_id, response[:response], 'assistant')
          puts "💾 Mensaje asistente guardado"
        end
        
        puts "✅ Enviando respuesta al cliente"
        app.status 200
        response.to_json
        
      rescue JSON::ParserError => e
        puts "❌ Error JSON: #{e.message}"
        app.halt 400, { error: 'JSON inválido', details: e.message }.to_json
      rescue StandardError => e
        puts "❌ Error en chat: #{e.class} - #{e.message}"
        puts e.backtrace.first(5)
        
        # Retornar error con respuesta de fallback
        app.status 500
        {
          error: e.message,
          response: "Lo siento, ocurrió un error al procesar tu mensaje. Por favor intenta de nuevo.",
          tools_used: []
        }.to_json
      end
    end

    def handle_image(app, request, params)
      app.content_type :json
      
      begin
        token = extract_token(request)
        
        # Obtener imagen
        image_file = params['image']
        app.halt 400, { error: 'Imagen requerida' }.to_json unless image_file
        
        # Procesar imagen con OCR
        text = FileParser.parse_image(image_file[:tempfile].path)
        
        # Procesar con el agente
        agent = Agent.new(token: token)
        response = agent.process_message("Analiza esta imagen: #{text}")
        
        app.status 200
        response.to_json
        
      rescue StandardError => e
        puts "❌ Error procesando imagen: #{e.message}"
        app.halt 500, { error: e.message }.to_json
      end
    end

    def handle_pdf(app, request, params)
      app.content_type :json
      
      begin
        token = extract_token(request)
        
        # Obtener PDF
        pdf_file = params['pdf']
        app.halt 400, { error: 'PDF requerido' }.to_json unless pdf_file
        
        # Extraer texto del PDF
        text = FileParser.parse_pdf(pdf_file[:tempfile].path)
        
        # Procesar con el agente
        agent = Agent.new(token: token)
        response = agent.process_message("Analiza este documento: #{text}")
        
        app.status 200
        response.to_json
        
      rescue StandardError => e
        puts "❌ Error procesando PDF: #{e.message}"
        app.halt 500, { error: e.message }.to_json
      end
    end

    def get_history(app, request, params)
      app.content_type :json
      
      begin
        token = extract_token(request)
        user_id = extract_user_id(token)
        
        app.halt 400, { error: 'User ID no disponible' }.to_json unless user_id
        
        # Obtener historial de la base de datos
        limit = params['limit']&.to_i || 20
        history = DB.instance.get_history(user_id, limit)
        
        # Formatear historial
        formatted = history.map do |row|
          {
            id: row[0],
            user_id: row[1],
            message: row[2],
            role: row[3],
            created_at: row[4]
          }
        end
        
        app.status 200
        { history: formatted.reverse }.to_json
        
      rescue StandardError => e
        puts "❌ Error obteniendo historial: #{e.message}"
        app.halt 500, { error: e.message }.to_json
      end
    end
    
    def clear_history(app, request, params)
      app.content_type :json
      
      begin
        token = extract_token(request)
        user_id = extract_user_id(token)
        
        app.halt 400, { error: 'User ID no disponible' }.to_json unless user_id
        
        DB.instance.clear_history(user_id)
        
        app.status 200
        { message: 'Historial eliminado', user_id: user_id }.to_json
        
      rescue StandardError => e
        puts "❌ Error eliminando historial: #{e.message}"
        app.halt 500, { error: e.message }.to_json
      end
    end

    private

    def extract_token(request)
      auth_header = request.env['HTTP_AUTHORIZATION']
      return nil unless auth_header
      
      auth_header.gsub(/^Bearer /, '')
    end
    
    def extract_user_id(token)
      return 'anonymous' unless token
      
      begin
        # Decodificar JWT para obtener user_id
        require 'base64'
        require 'json'
        
        parts = token.split('.')
        return 'anonymous' unless parts.length == 3
        
        payload = parts[1]
        # Agregar padding si es necesario
        payload += '=' * (4 - payload.length % 4) if payload.length % 4 != 0
        decoded = Base64.urlsafe_decode64(payload)
        data = JSON.parse(decoded)
        
        data['sub'] || data['user_id'] || data['id'] || 'anonymous'
      rescue StandardError => e
        puts "⚠️ No se pudo extraer user_id (#{e.class}): #{e.message}"
        'anonymous'
      end
    end
    
    def extract_user_info(token)
      return {} unless token
      
      begin
        require 'base64'
        require 'json'
        
        parts = token.split('.')
        return {} unless parts.length == 3
        
        payload = parts[1]
        payload += '=' * (4 - payload.length % 4) if payload.length % 4 != 0
        decoded = Base64.urlsafe_decode64(payload)
        data = JSON.parse(decoded)
        
        # Extraer username de diferentes campos posibles
        username = data['username'] || 
                   data['name'] || 
                   data['user_name'] ||
                   data['nombre'] ||
                   data['full_name'] ||
                   data['displayName']
        
        # Extraer email
        email = data['email'] || data['correo']
        
        # Extraer rol
        role = data['role'] || 
               data['tipo_usuario'] ||
               data['user_role'] ||
               data['tipo'] ||
               'paciente'
        
        user_info = {
          user_id: data['sub'] || data['user_id'] || data['id'],
          username: username,
          email: email,
          role: role,
          exp: data['exp']
        }
        
        puts "🔍 JWT decodificado: user_id=#{user_info[:user_id]}, username=#{user_info[:username] || 'no encontrado'}, role=#{user_info[:role]}"
        
        user_info
      rescue StandardError => e
        puts "⚠️ Error extrayendo info del usuario: #{e.message}"
        puts "📄 Token (primeros 50 chars): #{token[0..50]}..."
        {}
      end
    end
  end
end
