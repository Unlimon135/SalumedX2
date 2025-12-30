module MCP
  class ResumenVentas
    def self.execute(params, token)
      fecha_inicio = params[:fecha_inicio] || params['fecha_inicio'] || (Date.today - 30).to_s
      fecha_fin = params[:fecha_fin] || params['fecha_fin'] || Date.today.to_s
      
      puts "📊 Generando resumen de ventas: #{fecha_inicio} - #{fecha_fin}"
      
      # Llamar al servicio de reportes
      service = ReportService.new(token: token)
      reporte = service.resumen_ventas(fecha_inicio, fecha_fin)
      
      {
        tool: 'resumen_ventas',
        success: true,
        data: reporte,
        periodo: "#{fecha_inicio} - #{fecha_fin}"
      }
    rescue StandardError => e
      {
        tool: 'resumen_ventas',
        success: false,
        error: e.message
      }
    end
  end
end
