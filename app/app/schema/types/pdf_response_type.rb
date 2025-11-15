# schema/types/pdf_response_type.rb
module Types
  class PdfResponseType < GraphQL::Schema::Object
    description "Respuesta de la generación del PDF de receta"

    field :mensaje, String, null: false
    field :archivo, String, null: true
  end
end
