require 'httparty'

module GitLabAPI
  class Base
    include HTTParty

    def initialize(token)
      self.class.headers "PRIVATE-TOKEN" => token
    end

    def get(endpoint)
      response = self.class.get(endpoint)
      handle_response(response)
    end

    def post(endpoint, body)
      response = self.class.post(endpoint, body: body.to_json)
      handle_response(response)
    end

    def put(endpoint, body)
      response = self.class.put(endpoint, body: body.to_json)
      handle_response(response)
    end

    private

    def handle_response(response)
      unless response.code.between?(200, 299)
        error_message = "API Error: #{response.code} - #{response.message}"
        if response.parsed_response.is_a?(Hash) && response.parsed_response['error']
          error_message += " - Detail: #{response.parsed_response['error']}"
        elsif response.parsed_response.is_a?(Hash) && response.parsed_response['message']
          error_message += " - Detail: #{response.parsed_response['message']}"
        end
        raise StandardError, error_message
      end
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise StandardError, "Failed to parse JSON response: #{e.message}"
    end
  end
end
