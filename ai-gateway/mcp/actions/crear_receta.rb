module MCP
  class CrearReceta
    def self.execute(params, token)
      paciente = params[:paciente] || params['paciente']
      medico = params[:medico] || params['medico']
      detalles = params[:detalles] || params['detalles']
      
      raise "Parámetros 'paciente', 'medico' y 'detalles' requeridos" unless paciente && medico && detalles
      
      puts "✍️ Creando receta para paciente: #{paciente[:nombre]}"
      
      # Llamar al servicio de recetas
      service = RecetaService.new(token: token)
      receta = service.crear(paciente, medico, detalles)
      
      {
        tool: 'crear_receta',
        success: true,
        data: receta,
        message: 'Receta creada exitosamente'
      }
    rescue StandardError => e
      {
        tool: 'crear_receta',
        success: false,
        error: e.message
      }
    end
  end
end
