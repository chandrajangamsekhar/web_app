class IssueJwtToken
  require 'rest-client'
  require './lib/distributed_tracking'

  @@jwt_token = nil

  # calls plaid api users/login
  def self.api_gateway_token(tracking_id = nil, user_id = nil)
    begin
      tracking_id = DistributedTracking.x_request_id if tracking_id.nil?
      user_id = DistributedTracking.user_id if user_id.nil?
      payload = { email: $jwt_token_email, password: $jwt_token_password }
      # response = ApiClient.post("#{ENV['jwt_token_url']}/users/login", payload)
      response = RestClient::Request.execute(method: :post, 
        url: "#{$jwt_token_url}/users/login", 
        payload: payload, 
        headers: { content_type: "application/json", x_request_id: tracking_id, user_id: user_id })
      @@jwt_token = ActiveSupport::JSON.decode(response.body)['auth_token']
      Rails.cache.write('jwt_token', @@jwt_token) if Rails.cache.present?
      Log.info("API Auth Token Gateway Login called.")
    rescue RestClient::ExceptionWithResponse, RestClient::Exception, StandardError => e
      Log.error("Error occurred while issuing API auth token call #{$jwt_token_url}users/login with email #{$jwt_token_email}. ", e, true)
      raise
    end
  end

  def self.jwt_token
    jwt_token = Rails.cache.read('jwt_token') if Rails.cache.present?
    jwt_token = @@jwt_token if jwt_token.nil?
    jwt_token
  end
end
