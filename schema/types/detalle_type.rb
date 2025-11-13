# app/schema/types/detalle_type.rb
require_relative 'producto_type'

module Types
  class DetalleType < Types::BaseObject
    description "Representa el detalle de un producto dentro de una receta o prescripción"

    field :id, ID, null: false
    field :producto_id, ID, null: false
    field :cantidad, Integer, null: false
    field :indicaciones, String, null: true
    field :producto, Types::ProductoType, null: true
  end
end
