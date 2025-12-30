module MCP
  class VerReceta
    def self.execute(params, token)
      receta_id = params[:receta_id] || params['receta_id']
      
      raise "Parámetro 'receta_id' requerido" unless receta_id
      
      puts "📋 Consultando receta: #{receta_id}"
      
      # Llamar al servicio de recetas
      service = RecetaService.new(token: token)
      receta = service.obtener(receta_id)
      
      {
        tool: 'ver_receta',
        success: true,
        data: receta
      }
    rescue StandardError => e
      {
        tool: 'ver_receta',
        success: false,
        error: e.message
      }
    end
  end
end
