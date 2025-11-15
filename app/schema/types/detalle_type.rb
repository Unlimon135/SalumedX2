# app/schema/types/detalle_type.rb

module Types
  class DetalleType < Types::BaseObject
    description "Representa el detalle de un producto dentro de una receta o prescripción"

    field :id, ID, null: false
    field :producto_id, ID, null: false
    field :cantidad, Integer, null: false
    field :dosis, String, null: true
    field :presentacion, String, null: true
    field :duracion_tratamiento, String, null: true
    field :instrucciones, String, null: true
    field :indicaciones, String, null: true
    # Usar JSON para evitar problemas con dependencias circulares
    field :producto, GraphQL::Types::JSON, null: true

    # Normalizar nombres de campos
    def id
      object['id_detalle_receta'] || object['id'] || object['detalle_id']
    end

    def producto_id
      if object['producto'].is_a?(Hash)
        object['producto']['id_producto'] || object['producto']['id']
      else
        object['producto_id'] || object['productoId'] || object['producto']
      end
    end

    def cantidad
      object['cantidad'] || object['qty'] || 1
    end

    def dosis
      object['dosis'] || object['dosage']
    end

    def presentacion
      object['presentacion'] || object['presentation']
    end

    def duracion_tratamiento
      object['duracion_tratamiento'] || object['duracionTratamiento'] || object['duration']
    end

    def instrucciones
      object['instrucciones'] || object['indicaciones'] || object['instructions']
    end

    def indicaciones
      # Alias para instrucciones (retrocompatibilidad)
      instrucciones
    end

    def producto
      # Si producto es un objeto completo, devolverlo; si es solo ID, devolver nil
      object['producto'] if object['producto'].is_a?(Hash)
    end
  end
end
