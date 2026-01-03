class ChatController
  class << self
    def handle_message(request, params)
      content_type :json
      
      begin
        # Obtener token JWT
        token = extract_token(request)
        
        # Parsear body
        body = JSON.parse(request.body.read)
        message = body['message']
        
        halt 400, { error: 'Mensaje requerido' }.to_json unless message
        
        # Guardar mensaje del usuario
        user_id = extract_user_id(token)
        DB.instance.save_message(user_id, message, 'user') if user_id
        
        # Crear agente
        agent = Agent.new(token: token)
        
        # Procesar mensaje
        response = agent.process_message(message)
        
        # Guardar respuesta del asistente
        DB.instance.save_message(user_id, response[:response], 'assistant') if user_id
        
        status 200
        response.to_json
        
      rescue JSON::ParserError
        halt 400, { error: 'JSON inválido' }.to_json
      rescue StandardError => e
        puts "❌ Error en chat: #{e.message}"
        halt 500, { error: e.message }.to_json
      end
    end

    def handle_image(request, params)
      content_type :json
      
      begin
        token = extract_token(request)
        
        # Obtener imagen
        image_file = params['image']
        halt 400, { error: 'Imagen requerida' }.to_json unless image_file
        
        # Procesar imagen con OCR
        text = FileParser.parse_image(image_file[:tempfile].path)
        
        # Procesar con el agente
        agent = Agent.new(token: token)
        response = agent.process_message("Analiza esta imagen: #{text}")
        
        status 200
        response.to_json
        
      rescue StandardError => e
        puts "❌ Error procesando imagen: #{e.message}"
        halt 500, { error: e.message }.to_json
      end
    end

    def handle_pdf(request, params)
      content_type :json
      
      begin
        token = extract_token(request)
        
        # Obtener PDF
        pdf_file = params['pdf']
        halt 400, { error: 'PDF requerido' }.to_json unless pdf_file
        
        # Extraer texto del PDF
        text = FileParser.parse_pdf(pdf_file[:tempfile].path)
        
        # Procesar con el agente
        agent = Agent.new(token: token)
        response = agent.process_message("Analiza este documento: #{text}")
        
        status 200
        response.to_json
        
      rescue StandardError => e
        puts "❌ Error procesando PDF: #{e.message}"
        halt 500, { error: e.message }.to_json
      end
    end

    def get_history(request, params)
      content_type :json
      
      begin
        token = extract_token(request)
        user_id = extract_user_id(token)
        
        halt 400, { error: 'User ID no disponible' }.to_json unless user_id
        
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
        
        status 200
        { history: formatted.reverse }.to_json
        
      rescue StandardError => e
        puts "❌ Error obteniendo historial: #{e.message}"
        halt 500, { error: e.message }.to_json
      end
    end
    
    def clear_history(request, params)
      content_type :json
      
      begin
        token = extract_token(request)
        user_id = extract_user_id(token)
        
        halt 400, { error: 'User ID no disponible' }.to_json unless user_id
        
        DB.instance.clear_history(user_id)
        
        status 200
        { message: 'Historial eliminado', user_id: user_id }.to_json
        
      rescue StandardError => e
        puts "❌ Error eliminando historial: #{e.message}"
        halt 500, { error: e.message }.to_json
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
        
        payload = token.split('.')[1]
        decoded = Base64.urlsafe_decode64(payload + '=' * (4 - payload.length % 4))
        data = JSON.parse(decoded)
        
        data['sub'] || data['user_id'] || data['id'] || 'anonymous'
      rescue StandardError => e
        puts "⚠️ No se pudo extraer user_id: #{e.message}"
        'anonymous'
      end
    end
  end
end
