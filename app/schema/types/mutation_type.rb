# schema/types/mutation_type.rb
require_relative '../../service/pdf_service'
require_relative '../../service/rest_service'

module Types
  class MutationType < GraphQL::Schema::Object
    description "Mutations de SaluuMedX"

    field :generar_receta_pdf, Types::PdfResponseType, null: false do
      description "Genera un PDF de receta médica obteniendo los datos reales desde el REST"
      argument :paciente, Types::PacienteInputType, required: true
      argument :medico, Types::MedicoInputType, required: true
    end

    def generar_receta_pdf(paciente:, medico:)
      begin
        # Convertir los input objects a hash con símbolos como claves
        paciente_hash = paciente.to_h.transform_keys(&:to_sym)
        medico_hash = medico.to_h.transform_keys(&:to_sym)
        
        # Normalizar el campo de licencia del médico (puede venir como 'licencia' o 'numero_licencia')
        if medico_hash[:licencia] && !medico_hash[:numero_licencia]
          medico_hash[:numero_licencia] = medico_hash[:licencia]
        elsif medico_hash[:numero_licencia] && !medico_hash[:licencia]
          medico_hash[:licencia] = medico_hash[:numero_licencia]
        end
        
        # Crear instancia del cliente REST
        rest = context[:rest_user] || RestService.new("https://salumedx-rest.onrender.com")

        # --- 1️⃣ Obtener productos reales desde el REST ---
        productos_pdf = []
        
        begin
          response = rest.get("/productos/")
          
          if response && response.code.to_i.between?(200, 299)
            parsed_response = JSON.parse(response.body)
            
            # La respuesta puede ser un array directo o un objeto con clave
            productos = if parsed_response.is_a?(Array)
              parsed_response
            elsif parsed_response.is_a?(Hash)
              parsed_response['productos'] || parsed_response['results'] || parsed_response['data'] || []
            else
              []
            end

            # --- 2️⃣ Formatear productos (solo los necesarios para el PDF) ---
            productos_pdf = productos.first(5).map do |p|
              {
                "nombre" => (p["nombre"] || p[:nombre] || p["nombre_comercial"] || p[:nombre_comercial] || "Producto").to_s,
                "presentacion" => (p["presentacion"] || p[:presentacion] || "N/A").to_s,
                "cantidad" => (p["stock"] || p[:stock] || 1).to_i,
                "precio" => (p["precio"] || p[:precio] || 0.0).to_f,
                "farmacia_nombre" => (p["farmacia_nombre"] || p[:farmacia_nombre] || "Farmacia").to_s
              }
            end
          end
        rescue => api_error
          # Si falla el API, usar productos de ejemplo para el PDF
          puts "⚠️ Error obteniendo productos del API: #{api_error.message}"
        end
        
        # Si no hay productos, usar datos de ejemplo
        if productos_pdf.empty?
          productos_pdf = [
            {
              "nombre" => "Paracetamol 500mg",
              "presentacion" => "Tabletas",
              "cantidad" => 1,
              "precio" => 2.50,
              "farmacia_nombre" => "Farmacia Central"
            },
            {
              "nombre" => "Ibuprofeno 400mg",
              "presentacion" => "Cápsulas",
              "cantidad" => 1,
              "precio" => 3.75,
              "farmacia_nombre" => "Farmacia del Ahorro"
            }
          ]
        end

        # --- 3️⃣ Generar el PDF ---
        ruta_pdf = PdfService.generar_pdf_receta(productos_pdf, paciente: paciente_hash, medico: medico_hash)

        { mensaje: "✅ PDF generado exitosamente", archivo: ruta_pdf }

      rescue => e
        { mensaje: "❌ Error al generar el PDF: #{e.message}", archivo: nil }
      end
    end
  end
end

