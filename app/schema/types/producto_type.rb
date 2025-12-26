module Types
  class ProductoType < GraphQL::Schema::Object
    description "Representa un producto disponible en una farmacia"

    field :id, ID, null: false, description: "Identificador único del producto"
    field :nombre, String, null: false, description: "Nombre del producto"
    field :nombre_generico, String, null: true, description: "Nombre genérico"
    field :nombre_comercial, String, null: true, description: "Nombre comercial"
    field :principio_activo, String, null: true, description: "Principio activo"
    field :categoria, String, null: true, description: "Categoría del producto"
    field :descripcion, String, null: true, description: "Descripción del producto"
    field :precio, Float, null: true, description: "Precio del producto"
    field :stock, Integer, null: true, description: "Cantidad disponible en stock"
    field :presentacion, String, null: true, description: "Presentación del producto"
    field :concentracion, String, null: true, description: "Concentración del producto"
    field :requiere_receta, Boolean, null: true, description: "Requiere receta médica"
    field :farmacia_id, ID, null: true, description: "ID de la farmacia a la que pertenece"
    field :distanciaKm, Float, null: true, method: :distancia_km, description: "Distancia en kilómetros desde el punto de búsqueda"
    
    # Usar JSON en lugar de FarmaciaType para evitar dependencia circular
    field :farmacia, GraphQL::Types::JSON, null: true, description: "Datos de la farmacia asociada a este producto"
    field :farmaciaNombre, String, null: true, method: :farmacia_nombre, description: "Nombre de la farmacia asociada"

    # Resolvers para normalizar campos
    def id
      object['id_producto'] || object['id'] || object['producto_id']
    end

    def nombre
      object['nombre_comercial'] || object['nombre_generico'] || object['nombre'] || 'Sin nombre'
    end

    def nombre_generico
      object['nombre_generico'] || object['nombreGenerico']
    end

    def nombre_comercial
      object['nombre_comercial'] || object['nombreComercial']
    end

    def principio_activo
      object['principio_activo'] || object['principioActivo']
    end

    def categoria
      object['categoria'] || object['category']
    end

    def descripcion
      object['descripcion'] || object['description']
    end

    def presentacion
      object['presentacion'] || object['presentation']
    end

    def concentracion
      object['concentracion'] || object['concentration']
    end

    def requiere_receta
      object['requiere_receta'] || object['requiereReceta'] || false
    end

    def farmacia
      return nil unless object['farmacia_id'] || object[:farmacia_id]
      farmacia_id = object['farmacia_id'] || object[:farmacia_id]

      rest = context[:rest_user] || context[:rest]
      return nil unless rest

      context[:_farmacia_cache] ||= {}
      return context[:_farmacia_cache][farmacia_id] if context[:_farmacia_cache].key?(farmacia_id)

      begin
        response = rest.get("/farmacias/#{farmacia_id}/")
        if response.code.to_i == 200
          data = JSON.parse(response.body) rescue {}
          context[:_farmacia_cache][farmacia_id] = data
        else
          context[:_farmacia_cache][farmacia_id] = nil
        end
      rescue StandardError => e
        context[:_farmacia_cache][farmacia_id] = nil
      end
      context[:_farmacia_cache][farmacia_id]
    end

    def farmacia_nombre
      data = farmacia
      return nil unless data.is_a?(Hash)
      data['nombre_comercial'] || data['nombre']
    end
  end
end
