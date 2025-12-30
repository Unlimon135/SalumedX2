require 'mini_magick'
require 'rtesseract'
require 'pdf-reader'

class FileParser
  # Procesar imagen con OCR
  def self.parse_image(image_path)
    puts "📷 Procesando imagen: #{image_path}"
    
    # Optimizar imagen para OCR
    image = MiniMagick::Image.open(image_path)
    image.colorspace 'Gray'
    image.contrast
    
    # Extraer texto con Tesseract
    text = RTesseract.new(image.path, lang: 'spa').to_s
    
    text.strip
  rescue StandardError => e
    puts "❌ Error procesando imagen: #{e.message}"
    "Error: No se pudo procesar la imagen"
  end

  # Extraer texto de PDF
  def self.parse_pdf(pdf_path)
    puts "📄 Procesando PDF: #{pdf_path}"
    
    reader = PDF::Reader.new(pdf_path)
    text = reader.pages.map(&:text).join("\n")
    
    text.strip
  rescue StandardError => e
    puts "❌ Error procesando PDF: #{e.message}"
    "Error: No se pudo procesar el PDF"
  end

  # Analizar imagen con IA (sin OCR)
  def self.analyze_image_with_ai(image_path, llm)
    # Convertir imagen a base64
    require 'base64'
    image_data = Base64.strict_encode64(File.read(image_path))
    
    prompt = "Analiza esta imagen médica y describe lo que ves"
    
    # Nota: Gemini Pro Vision soporta análisis de imágenes
    # Aquí iría la llamada específica con la imagen
    llm.generate_response("#{prompt}\n[Imagen adjunta]")
  end
end
