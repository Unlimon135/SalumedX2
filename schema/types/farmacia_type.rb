# schema/types/farmacia_type.rb
module Types
  class FarmaciaType < GraphQL::Schema::Object
    description "Representa una farmacia"

    field :id, ID, null: false, description: "Identificador único de la farmacia"
    field :nombre, String, null: false, description: "Nombre de la farmacia"
    field :direccion, String, null: true, description: "Dirección de la farmacia"
    field :telefono, String, null: true, description: "Teléfono de contacto"
    field :latitud, Float, null: true, description: "Latitud de la ubicación"
    field :longitud, Float, null: true, description: "Longitud de la ubicación"
    field :distancia_km, Float, null: true, description: "Distancia en kilómetros (solo en búsquedas por cercanía)"
    
    # Campo adicional para compatibilidad con la API
    field :farmacia_nombre, String, null: true, description: "Alias del nombre"
    
    def farmacia_nombre
      object['nombre'] || object['farmacia_nombre']
    end
  end
end

