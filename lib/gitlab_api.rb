
require 'httparty'
require 'json'

class GitlabApi
  attr_reader :api_endpoint, :token

  def initialize(api_endpoint, token)
    @api_endpoint = api_endpoint
    @token = token
  end

  def get(path)
    request(:get, path)
  end

  def post(path, body)
    request(:post, path, body)
  end

  def put(path, body)
    request(:put, path, body)
  end

  private

  def request(method, path, body = nil)
    headers = {
      "Content-Type" => "application/json",
      "PRIVATE-TOKEN" => token
    }
    options = { headers: headers }
    options[:body] = body.to_json if body
    response = HTTParty.send(method, "#{api_endpoint}#{path}", options)
    handle_response(response)
  end

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
