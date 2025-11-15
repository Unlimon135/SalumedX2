module Types
  class QueryType < Types::BaseObject
    # ===== RECETAS =====
    field :recetas, [Types::RecetaType], null: false, description: "Obtiene todas las recetas"
    def recetas
      resolver = RecetasResolver.new(context[:rest_user])
      resolver.listar
    end
    
    field :receta, Types::RecetaType, null: true do
      description "Obtiene una receta por ID"
      argument :id, ID, required: true
    end
    def receta(id:)
      resolver = RecetasResolver.new(context[:rest_user])
      resolver.por_id(id)
    end

    # ===== PACIENTES =====
    field :pacientes, [Types::PacienteType], null: false, description: "Obtiene todos los pacientes"
    def pacientes
      rest = context[:rest_user]
      response = rest.get("/paciente-info/")
      
      # Si el endpoint no existe o da error, devolver array vacío
      return [] unless response && response.code.to_i.between?(200, 299)
      
      data = JSON.parse(response.body) rescue {}
      pacientes_array = data["pacientes"] || []
      
      # Mapear los datos del API al formato esperado
      pacientes_array.map do |p|
        {
          'id' => p['paciente_id'] || p['id'],
          'nombre' => p['nombre_completo'] || p['username'],
          'cedula' => p['cedula'],
          'email' => p['email'],
          'telefono' => p['telefono'],
          'direccion' => p['direccion'],
          'fecha_nacimiento' => p['fecha_nacimiento']
        }
      end
    rescue => e
      raise GraphQL::ExecutionError, "Error obteniendo pacientes: #{e.message}"
    end

    field :paciente, Types::PacienteType, null: true do
      description "Obtiene un paciente por ID"
      argument :id, ID, required: true
    end
    def paciente(id:)
      rest = context[:rest_user]
      response = rest.get("/paciente-info/?id=#{id}")
      return nil unless response && response.code.to_i.between?(200, 299)
      
      data = JSON.parse(response.body) rescue {}
      pacientes_array = data["pacientes"] || []
      p = pacientes_array.first
      return nil unless p
      
      {
        'id' => p['paciente_id'] || p['id'],
        'nombre' => p['nombre_completo'] || p['username'],
        'cedula' => p['cedula'],
        'email' => p['email'],
        'telefono' => p['telefono'],
        'direccion' => p['direccion'],
        'fecha_nacimiento' => p['fecha_nacimiento']
      }
    rescue => e
      nil
    end

    # ===== PRODUCTOS =====
    field :productos, [Types::ProductoType], null: false do
      description "Obtiene todos los productos"
      argument :nombre, String, required: false
    end
    def productos(nombre: nil)
      resolver = ProductoResolver.new(context[:rest_user])
      if nombre
        resolver.buscar_productos(nombre: nombre)
      else
        rest = context[:rest_user]
        response = rest.get("/productos/")
        return [] unless response.code.to_i.between?(200, 299)
        
        data = JSON.parse(response.body) rescue {}
        productos_array = if data.is_a?(Array)
          data
        elsif data.is_a?(Hash)
          data['productos'] || data['results'] || []
        else
          []
        end
        Array(productos_array)
      end
    end

    # ===== FARMACIAS =====
    field :farmacias, [Types::FarmaciaType], null: false, description: "Obtiene todas las farmacias"
    def farmacias
      rest = context[:rest_user]
      response = rest.get("/farmacias/")
      return [] unless response.code.to_i.between?(200, 299)
      
      data = JSON.parse(response.body) rescue {}
      farmacias_array = data["farmacias"] || data["results"] || data || []
      Array(farmacias_array)
    end

    field :farmacia, Types::FarmaciaType, null: true do
      description "Obtiene una farmacia por ID"
      argument :id, ID, required: true
    end
    def farmacia(id:)
      rest = context[:rest_user]
      response = rest.get("/farmacias/#{id}/")
      return nil unless response.code.to_i.between?(200, 299)
      
      JSON.parse(response.body) rescue nil
    end

    # ===== PRECIOS MÁS BARATOS =====
    field :precios_mas_baratos, [Types::ProductoType], null: false, camelize: true do
      description "Busca los precios más baratos de un producto en farmacias cercanas"
      argument :nombre, String, required: true
      argument :lat, GraphQL::Types::Float, required: true
      argument :lng, GraphQL::Types::Float, required: true
      argument :radio_km, GraphQL::Types::Float, required: true
    end
    def precios_mas_baratos(nombre:, lat:, lng:, radio_km:)
      resolver = ProductoResolver.new(context[:rest_user])
      resolver.buscar_productos(nombre: nombre)
    end
  end
end

