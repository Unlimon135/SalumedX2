require 'prawn'
require 'prawn/table'

class PdfService
  # Genera un PDF y lo guarda en public/pdfs para que sea accesible vía HTTP
  # Retorna la URL relativa (ej: "/pdfs/archivo.pdf") para abrir en otra pestaña
  def self.generar_pdf_receta(productos, paciente:, medico:)
    # Resolver rutas de forma robusta (independiente del cwd)
    public_folder = File.expand_path('../public', __dir__)
    pdfs_dir      = File.join(public_folder, 'pdfs')

    # Asegurar carpeta public/pdfs
    Dir.mkdir(pdfs_dir) unless Dir.exist?(pdfs_dir)

    # Construir nombre de archivo seguro
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    pac_name  = (paciente[:nombre] || 'paciente').to_s.downcase
    pac_name  = pac_name.gsub(' ', '_').gsub(/[^0-9A-Za-z_\-]+/, '_')
    cedula    = (paciente[:cedula] || 'NA').to_s.gsub(/[^0-9A-Za-z]+/, '')
    filename  = "receta_#{pac_name}_#{cedula}_#{timestamp}.pdf"
    fullpath  = File.join(pdfs_dir, filename)

    # Intentar cargar logo desde public/img o public/images
    logo_img_path = File.join(public_folder, 'img', 'logo_empresa.png')
    logo_img_path = File.join(public_folder, 'images', 'logo_empresa.png') unless File.exist?(logo_img_path)

    # Generar PDF
    Prawn::Document.generate(fullpath, page_size: 'A4') do |pdf|
      # --- LOGO ---
      if File.exist?(logo_img_path)
        pdf.image logo_img_path, width: 100, position: :center
        pdf.move_down 20
      end

      # --- ENCABEZADO ---
      pdf.text 'Receta Médica - SaluMedX', size: 20, style: :bold, align: :center
      pdf.move_down 10
      pdf.stroke_horizontal_rule
      pdf.move_down 20

      # --- DATOS DEL MÉDICO Y PACIENTE ---
      pdf.text "Médico: #{medico[:nombre]} (Licencia ##{medico[:licencia] || 'N/A'})", size: 12
      pdf.text "Paciente: #{paciente[:nombre]} (Cédula: #{paciente[:cedula] || 'N/A'})", size: 12
      pdf.text "Fecha: #{Time.now.strftime('%d/%m/%Y')}", size: 12
      pdf.move_down 20

      # --- TABLA DE PRODUCTOS ---
      data = [[
        'Producto', 'Presentación', 'Cantidad', 'Precio (USD)', 'Farmacia'
      ]] + Array(productos).map do |p|
        [
          p['nombre'],
          p['presentacion'] || '-',
          p['cantidad'] || 1,
          sprintf('$%.2f', p['precio'].to_f),
          p['farmacia_nombre'] || 'N/A'
        ]
      end

      pdf.table(data, header: true, width: pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = 'DDDDDD'
        columns(3).align = :right
      end

      # --- TOTAL ---
      pdf.move_down 20
      total = Array(productos).sum { |p| p['precio'].to_f * (p['cantidad'] || 1) }
      pdf.text "Total estimado: $#{sprintf('%.2f', total)}", size: 14, style: :bold

      # --- FIRMA Y PIE ---
      pdf.move_down 40
      pdf.text 'Firma del médico: ____________________________', align: :right
      pdf.move_down 20
      pdf.text 'Gracias por utilizar SaluMedX', align: :center, size: 10, style: :italic
    end

    # Devolver URL relativa que el frontend puede abrir en otra pestaña
    "/pdfs/#{filename}"
  end
end
