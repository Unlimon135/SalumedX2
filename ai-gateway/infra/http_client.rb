require 'httparty'

class HTTPClient
  def graphql_request(query, variables = {}, token = nil)
    headers = { 'Content-Type' => 'application/json' }
    headers['Authorization'] = "Bearer #{token}" if token

    response = HTTParty.post(
      Settings.graphql_url,
      headers: headers,
      body: { query: query, variables: variables }.to_json,
      timeout: 30
    )

    if response.success?
      JSON.parse(response.body)
    else
      raise "GraphQL Error: #{response.code} - #{response.body}"
    end
  rescue StandardError => e
    puts "❌ Error en GraphQL request: #{e.message}"
    { errors: [{ message: e.message }] }
  end

  def rest_request(url, method: :get, body: nil, token: nil)
    headers = { 'Content-Type' => 'application/json' }
    headers['Authorization'] = "Bearer #{token}" if token

    options = { headers: headers, timeout: 30 }
    options[:body] = body.to_json if body

    response = case method
               when :get
                 HTTParty.get(url, options)
               when :post
                 HTTParty.post(url, options)
               when :patch
                 HTTParty.patch(url, options)
               when :delete
                 HTTParty.delete(url, options)
               else
                 raise "Método HTTP no soportado: #{method}"
               end

    if response.success?
      JSON.parse(response.body)
    else
      raise "REST Error: #{response.code} - #{response.body}"
    end
  rescue StandardError => e
    puts "❌ Error en REST request: #{e.message}"
    { error: e.message }
  end
end
