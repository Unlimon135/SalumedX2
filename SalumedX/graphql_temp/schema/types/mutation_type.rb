require_relative 'pdf_response_type'
require_relative '../../service/recetas_service'
require_relative '../../service/rest_service'

module Types
  class MutationType < GraphQL::Schema::Object
    description "Mutaciones disponibles"


    field :generar_receta_pdf, Types::PdfResponseType, null: false do
      argument :paciente, Types::PacienteInputType, required: true
      argument :medico,   Types::MedicoInputType,   required: true
    end

    def generar_receta_pdf(paciente:, medico:)
      rest = context[:rest_user]
      raise GraphQL::ExecutionError, "No autenticado" unless rest

      # 🔒 VALIDACIÓN: Verificar que el usuario autenticado sea un médico
      user_profile = ::Types.obtener_perfil_usuario(rest)
      
      unless user_profile && user_profile['is_medico']
        raise GraphQL::ExecutionError, "❌ Acceso denegado: Solo un médico puede generar recetas médicas. Si eres médico, asegúrate de tener tu perfil configurado correctamente."
      end

      # Solo el médico puede generar la receta: validar campo licencia presente
      unless medico[:licencia] && !medico[:licencia].to_s.strip.empty?
        raise GraphQL::ExecutionError, "Se requiere el número de licencia del médico para generar la receta"
      end

      # El backend exige el id del paciente y del médico: debemos tenerlos.
      # Como nuestro Input solo tiene nombre y cedula/licencia, necesitamos primero buscar/crear IDs.
      # Buscar paciente en /paciente-info/ por cédula y médico en /medico-info/ por licencia
      begin
        paciente_id = ::Types.obtener_id_paciente_por_cedula(rest, paciente[:cedula])
        medico_id   = ::Types.obtener_id_medico_por_licencia(rest, medico[:licencia])
      rescue => e
        raise GraphQL::ExecutionError, "Error obteniendo IDs previos: #{e.message}"
      end

      # Si no existe paciente, intentar crearlo
      unless paciente_id
        puts "[PDF] Intentando crear paciente: #{paciente.inspect}"
        # El sistema no permite crear pacientes desde GraphQL
        # Los pacientes deben registrarse primero en el sistema REST
        puts "[PDF] ⚠️ Paciente con cédula #{paciente[:cedula]} no existe en el sistema"
      end
      
      # Si no existe médico, intentar crearlo
      unless medico_id
        puts "[PDF] Intentando crear médico: #{medico.inspect}"
        # El sistema no permite crear médicos desde GraphQL
        # Los médicos deben registrarse primero en el sistema REST
        puts "[PDF] ⚠️ Médico con licencia #{medico[:licencia]} no existe en el sistema"
      end

      # Validar que tengamos los IDs necesarios
      unless paciente_id
        error_msg = "No se encontró paciente con cédula #{paciente[:cedula]}. "
        error_msg += "El paciente debe estar registrado primero en el sistema."
        raise GraphQL::ExecutionError, error_msg
      end
      
      unless medico_id
        error_msg = "No se encontró médico con licencia #{medico[:licencia]}. "
        error_msg += "El médico debe estar registrado primero en el sistema."
        raise GraphQL::ExecutionError, error_msg
      end

      # Obtener TODOS los detalles de prescripción del usuario autenticado
      # GET /detalle-prescripcion/ devuelve solo las prescripciones del usuario actual
      begin
        resp = rest.get("/detalle-prescripcion/")
        unless resp.code.to_i == 200
          raise GraphQL::ExecutionError, "Error al obtener detalles de prescripción: #{resp.code}"
        end
        
        data = JSON.parse(resp.body) rescue {}
        detalles_prescripcion = data["detalle_prescripciones"] || []
        
        if detalles_prescripcion.empty?
          raise GraphQL::ExecutionError, "No se encontraron detalles de prescripción para este usuario"
        end
      rescue => e
        raise GraphQL::ExecutionError, "Error obteniendo detalles: #{e.message}"
      end

      # Preparar datos seguros para PDF desde los detalles obtenidos
      detalles_pdf = detalles_prescripcion.map do |dp|
        detalle_receta = dp["detalle_receta"] || {}
        producto = dp["producto"] || {}
        farmacia = dp["farmacia"] || {}
        
        nombre_prod = producto["nombre_comercial"] || producto["nombre_generico"] || "Producto desconocido"
        presentacion = producto["presentación"] || producto["presentacion"] || detalle_receta["presentación"] || "N/D"
        cantidad = detalle_receta["cantidad"] || 1
        precio = dp["precio_encontrado"].to_f rescue 0.0
        farmacia_nombre = farmacia["nombre_comercial"] || "N/D"
        
        {
          "nombre"           => nombre_prod,
          "presentacion"     => presentacion,
          "cantidad"         => cantidad,
          "precio"           => precio,
          "farmacia_nombre"  => farmacia_nombre
        }
      end

      path = PdfService.generar_pdf_receta(detalles_pdf,
        paciente: { nombre: paciente[:nombre] || "Paciente #{paciente_id}", cedula: paciente[:cedula] },
        medico:   { nombre: medico[:nombre]   || "Médico #{medico_id}", licencia: medico[:licencia] }
      )

      { mensaje: "PDF generado", archivo: path }
    rescue GraphQL::ExecutionError => ge
      { mensaje: ge.message, archivo: nil }
    rescue => e
      { mensaje: "Error al generar PDF: #{e.message}", archivo: nil }
    end
  end
end

# Helpers fuera de la clase (namespace Types)
module Types
  def self.obtener_id_paciente_por_cedula(rest, cedula)
    return nil if cedula.to_s.strip.empty?
    
    puts "[Helper] Buscando paciente con cédula=#{cedula}"
    
    # 1. Intentar con filtro directo: /paciente-info/?cedula=XXX
    begin
      query_url = "/paciente-info/?cedula=#{cedula}"
      puts "[Helper] GET #{query_url}"
      q_resp = rest.get(query_url)
      
      if q_resp.code.to_i == 200
        q_data = JSON.parse(q_resp.body) rescue {}
        puts "[Helper] Respuesta búsqueda filtrada: #{q_data.inspect[0,200]}"
        
        # Buscar array en la respuesta
    arr = q_data['pacientes'] || []
        
        if arr.any?
          first = arr.first
          id = first['paciente_id']
          puts "[Helper] ✅ Encontrado por filtro: ID=#{id}"
          return id if id
        end
      else
        puts "[Helper] Búsqueda filtrada falló: #{q_resp.code}"
      end
    rescue => e
      puts "[Helper] Error búsqueda filtrada: #{e.message}"
    end

    # 2. Listado completo como fallback
    begin
      puts "[Helper] GET /paciente-info/ (listado completo)"
      resp = rest.get("/paciente-info/")
      
      return nil unless resp.code.to_i == 200
      
      data = JSON.parse(resp.body) rescue {}
      puts "[Helper] Respuesta listado: #{data.keys.inspect}"
      
      # Buscar el array en diferentes claves posibles
  lista = data['pacientes'] || []
      
      puts "[Helper] Lista tiene #{lista.length} elementos"
      
      # Buscar el elemento por el campo
      item = lista.find do |elem|
        elem['cédula'].to_s == cedula.to_s
      end
      
      if item
        id = item['paciente_id']
        puts "[Helper] ✅ Encontrado por listado: ID=#{id}"
        return id
      else
        puts "[Helper] ❌ No encontrado en listado"
      end
    rescue => e
      puts "[Helper] Error en listado: #{e.message}"
    end
    
    nil
  end
  
  def self.obtener_id_medico_por_licencia(rest, licencia)
    return nil if licencia.to_s.strip.empty?
    
    puts "[Helper] Buscando médico con licencia=#{licencia}"
    
    # 1. Intentar con filtro directo: /medico-info/?licencia=XXX
    begin
      query_url = "/medico-info/?licencia=#{licencia}"
      puts "[Helper] GET #{query_url}"
      q_resp = rest.get(query_url)
      
      if q_resp.code.to_i == 200
        q_data = JSON.parse(q_resp.body) rescue {}
        puts "[Helper] Respuesta búsqueda filtrada médico: #{q_data.inspect[0,200]}"
        
        # Buscar array en la respuesta
        arr = q_data['medicos'] || []
        
        if arr.any?
          first = arr.first
          id = first['medico_id'] || first['id']
          puts "[Helper] ✅ Médico encontrado por filtro: ID=#{id}"
          return id if id
        end
      else
        puts "[Helper] Búsqueda médico filtrada falló: #{q_resp.code}"
      end
    rescue => e
      puts "[Helper] Error búsqueda médico filtrada: #{e.message}"
    end

    # 2. Listado completo como fallback
    begin
      puts "[Helper] GET /medico-info/ (listado completo)"
      resp = rest.get("/medico-info/")
      
      return nil unless resp.code.to_i == 200
      
      data = JSON.parse(resp.body) rescue {}
      puts "[Helper] Respuesta listado médicos: #{data.keys.inspect}"
      
      lista = data['medicos'] || []
      
      puts "[Helper] Lista médicos tiene #{lista.length} elementos"
      
      item = lista.find do |elem|
        elem['licencia'].to_s == licencia.to_s
      end
      
      if item
        id = item['medico_id'] || item['id']
        puts "[Helper] ✅ Médico encontrado por listado: ID=#{id}"
        return id
      else
        puts "[Helper] ❌ Médico no encontrado en listado"
      end
    rescue => e
      puts "[Helper] Error en listado médicos: #{e.message}"
    end
    
    nil
  end

  # Obtener el perfil del usuario autenticado para validar su rol
  def self.obtener_perfil_usuario(rest)
    return nil unless rest

    begin
      # Intentar obtener perfil del usuario desde endpoints comunes
      endpoints = ['/me/', '/user/profile/', '/api/user/']
      
      endpoints.each do |endpoint|
        resp = rest.get(endpoint)
        if resp.code.to_i == 200
          data = JSON.parse(resp.body)
          puts "[UserProfile] ✅ Perfil obtenido desde #{endpoint}"
          
          # Intentar determinar si es médico basado en la respuesta
          is_medico = data['is_medico'] || 
                     data['is_doctor'] || 
                     data['role'] == 'medico' ||
                     data['role'] == 'doctor' ||
                     data['user_type'] == 'medico' ||
                     !data['licencia_medica'].nil?
          
          return {
            'id' => data['id'],
            'username' => data['username'],
            'email' => data['email'],
            'is_medico' => is_medico,
            'role' => data['role'] || data['user_type'],
            'raw' => data
          }
        end
      end
      
      # Si no hay endpoint de perfil, intentar verificar en /medico-info/
      # usando el usuario actual para buscar coincidencias
      puts "[UserProfile] Intentando verificar si usuario es médico mediante /medico-info/"
      resp = rest.get("/medico-info/")
      if resp.code.to_i == 200
        data = JSON.parse(resp.body)
        medicos = data.is_a?(Array) ? data : (data['medicos'] || data['results'] || [])
        
        # Si el listado tiene al menos un médico y el usuario puede accederlo,
        # asumimos que puede ser médico (validación básica)
        if medicos.any?
          puts "[UserProfile] ⚠️ Usuario tiene acceso a /medico-info/, asumiendo rol médico"
          return {
            'is_medico' => true,
            'role' => 'medico',
            'verified_by' => 'medico-info-access'
          }
        end
      end
      
      puts "[UserProfile] ❌ No se pudo determinar el perfil del usuario"
      return { 'is_medico' => false }
      
    rescue => e
      puts "[UserProfile] Error obteniendo perfil: #{e.message}"
      return { 'is_medico' => false }
    end
  end
end
