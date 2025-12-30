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
        
        # Crear agente
        agent = Agent.new(token: token)
        
        # Procesar mensaje
        response = agent.process_message(message)
        
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
        
        # TODO: Implementar base de datos para historial
        history = []
        
        status 200
        { history: history }.to_json
        
      rescue StandardError => e
        halt 500, { error: e.message }.to_json
      end
    end

    private

    def extract_token(request)
      auth_header = request.env['HTTP_AUTHORIZATION']
      return nil unless auth_header
      
      auth_header.gsub(/^Bearer /, '')
    end
  end
end
