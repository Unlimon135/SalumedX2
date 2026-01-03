class RecetaService
  def initialize(token: nil)
    @token = token
    @http = HTTPClient.new
  end

  def obtener(receta_id)
    query = <<~GRAPHQL
      query($id: ID!) {
        receta(id: $id) {
          id
          fechaEmision
          pacienteId
          medicoId
          observaciones
          detalles {
            id
            productoId
            cantidad
            indicaciones
          }
        }
      }
    GRAPHQL

    response = @http.graphql_request(query, { id: receta_id }, @token)
    
    if response['data'] && response['data']['receta']
      response['data']['receta']
    else
      raise "Receta no encontrada"
    end
  end

  def crear(paciente, medico, detalles)
    mutation = <<~GRAPHQL
      mutation($pac: PacienteInput!, $med: MedicoInput!) {
        generarRecetaPdf(paciente: $pac, medico: $med) {
          mensaje
          archivo
        }
      }
    GRAPHQL

    variables = {
      pac: paciente,
      med: medico
    }

    response = @http.graphql_request(mutation, variables, @token)
    
    if response['data'] && response['data']['generarRecetaPdf']
      response['data']['generarRecetaPdf']
    else
      raise "Error creando receta: #{response['errors']}"
    end
  end

  def listar
    query = <<~GRAPHQL
      query {
        recetas {
          id
          fechaEmision
          pacienteId
          medicoId
        }
      }
    GRAPHQL

    response = @http.graphql_request(query, {}, @token)
    
    if response['data'] && response['data']['recetas']
      response['data']['recetas']
    else
      []
    end
  end
end
