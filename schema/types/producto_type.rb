# schema/types/producto_type.rb
module Types
  class ProductoType < GraphQL::Schema::Object
    description "Representa un producto disponible en una farmacia"

    field :id, ID, null: false, description: "Identificador único del producto"
    field :nombre, String, null: false, description: "Nombre del producto"
    field :descripcion, String, null: true, description: "Descripción del producto"
    field :precio, Float, null: true, description: "Precio del producto"
    field :stock, Integer, null: true, description: "Cantidad disponible en stock"
    field :presentacion, String, null: true, description: "Presentación del producto"
    field :farmacia_id, ID, null: true, description: "ID de la farmacia a la que pertenece"
    # Distancia (en km) si el backend la incluye en los resultados (ej: búsquedas geográficas)
    field :distanciaKm, Float, null: true, method: :distancia_km,
      description: "Distancia en kilómetros desde el punto de búsqueda" 

    # ⚡ Campo que devuelve datos de la farmacia asociada (sin dependencias cruzadas)
    field :farmacia, GraphQL::Types::JSON, null: true,
      description: "Datos de la farmacia asociada a este producto"

    # Campo derivado que expone solo el nombre comercial de la farmacia.
    # Al estar definido en snake_case, GraphQL-Ruby lo expone como farmaciaNombre.
    # Exponer el nombre en camelCase directamente para evitar problemas de configuración de camelización.
    field :farmaciaNombre, String, null: true, method: :farmacia_nombre,
      description: "Nombre de la farmacia asociada" 

    # Método que actúa como resolver del campo anterior
    def farmacia
      return nil unless object['farmacia_id'] || object[:farmacia_id]
      farmacia_id = object['farmacia_id'] || object[:farmacia_id]

      # Usar el cliente REST autenticado consistente con otros resolvers (rest_user)
      rest = context[:rest_user] || context[:rest]
      return nil unless rest

      # Cache simple en el contexto para evitar múltiples llamadas N+1
      context[:_farmacia_cache] ||= {}
      return context[:_farmacia_cache][farmacia_id] if context[:_farmacia_cache].key?(farmacia_id)

      begin
        response = rest.get("/farmacias/#{farmacia_id}/")
        if response.code.to_i == 200
          data = JSON.parse(response.body) rescue {}
          context[:_farmacia_cache][farmacia_id] = data
        else
          warn "[ProductoType] Error REST farmacia #{farmacia_id}: #{response.code}"
          context[:_farmacia_cache][farmacia_id] = nil
        end
      rescue StandardError => e
        warn "[ProductoType] Excepción obteniendo farmacia #{farmacia_id}: #{e.message}"
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
