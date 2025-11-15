# models/producto.rb
class ProductoModel
  attr_accessor :id, :nombre, :precio, :presentacion, :stock, :farmacia_id

  def initialize(data)
    @id = data['id']
    @nombre = data['nombre']
    @precio = data['precio']
    @presentacion = data['presentacion']
    @stock = data['stock']
    @farmacia_id = data['farmacia_id']
  end
end
