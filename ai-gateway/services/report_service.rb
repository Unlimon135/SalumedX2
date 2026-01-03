class ReportService
  def initialize(token: nil)
    @token = token
    @http = HTTPClient.new
  end

  def resumen_ventas(fecha_inicio, fecha_fin)
    # Simulación de reporte
    # En producción, conectar a base de datos o API
    {
      total_ventas: rand(50..200),
      monto_total: rand(1000..5000),
      productos_mas_vendidos: [
        { nombre: 'Paracetamol', cantidad: rand(20..50) },
        { nombre: 'Ibuprofeno', cantidad: rand(15..40) },
        { nombre: 'Amoxicilina', cantidad: rand(10..30) }
      ],
      recetas_emitidas: rand(30..80),
      periodo: {
        inicio: fecha_inicio,
        fin: fecha_fin
      }
    }
  end

  def estadisticas_diarias
    {
      fecha: Date.today.to_s,
      recetas_hoy: rand(5..15),
      consultas_productos: rand(20..50),
      usuarios_activos: rand(10..30)
    }
  end
end
