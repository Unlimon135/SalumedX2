module Types
  class FarmaciaType < GraphQL::Schema::Object
    description "Representa una farmacia con sus detalles y productos disponibles"

    field :id, ID, null: false, description: "Identificador único de la farmacia"
    field :nombre, String, null: false, description: "Nombre de la farmacia"
    field :direccion, String, null: false, description: "Dirección de la farmacia"
    field :lat, Float, null: true, description: "Latitud de la ubicación de la farmacia"
    field :lng, Float, null: true, description: "Longitud de la ubicación de la farmacia"
    field :distancia_km, Float, null: true, description: "Distancia desde el punto de referencia en kilómetros"

    # Usar JSON en lugar de ProductoType para evitar dependencia circular
    field :productos, GraphQL::Types::JSON, null: true, description: "Lista de productos disponibles en la farmacia"

    def productos
      return nil unless object['id']
      rest = context[:rest_user] || context[:rest]
      return nil unless rest

      begin
        response = rest.get("/productos/?farmacia_id=#{object['id']}")
        if response.code.to_i == 200
          JSON.parse(response.body)
        else
          nil
        end
      rescue StandardError => e
        nil
      end
    end
  end
end

