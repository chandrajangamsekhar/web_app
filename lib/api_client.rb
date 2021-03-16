require 'rest-client'
require './lib/issue_jwt_token'
require './lib/distributed_tracking'
require 'json'

class ApiClient
  
  def self.get(endpoint_url, url_payload, user_id = nil, tracking_id = nil)
    full_url = payload_to_url(endpoint_url, url_payload)
    rest_client_execute(:get, full_url, "", tracking_id, user_id)
  end

  def self.post(endpoint_url, json_payload, user_id = nil, tracking_id = nil)
    rest_client_execute(:post, endpoint_url, json_payload, tracking_id, user_id)
  end

  def self.put(endpoint_url, json_payload, user_id = nil, tracking_id = nil)
    rest_client_execute(:put, endpoint_url, json_payload, tracking_id, user_id)
  end

  def self.patch(endpoint_url, json_payload, user_id = nil, tracking_id = nil)
    rest_client_execute(:patch, endpoint_url, json_payload, tracking_id, user_id)
  end

  def self.delete(endpoint_url, url_payload, user_id = nil, tracking_id = nil)
    full_url = payload_to_url(endpoint_url, url_payload)
    rest_client_execute(:delete, full_url, "", tracking_id, user_id)
  end

  # Async versions of the above synchronous methods
  # callback MUST have one response parameter, and should be passed as method(:callback_method)
  def self.get_async(endpoint_url, url_payload, callback = nil, timeout = 20)
    get_async_add_to_response(RequestParams.new(:get, endpoint_url, url_payload, callback, timeout))
  end

  def self.post_async(endpoint_url, json_payload, callback = nil, timeout = 20)
    post_async_add_to_response(RequestParams.new(:post, endpoint_url, url_payload, callback, timeout))
  end

  def self.put_async(endpoint_url, json_payload, callback = nil, timeout = 20)
    put_async_add_to_response(RequestParams.new(:put, endpoint_url, url_payload, callback, timeout))
  end

  def self.patch_async(endpoint_url, json_payload, callback = nil, timeout = 20)
    patch_async_add_to_response(RequestParams.new(:patch, endpoint_url, url_payload, callback, timeout))
  end

  def self.delete_async(endpoint_url, url_payload, callback = nil, timeout = 20)
    delete_async_add_to_response(RequestParams.new(:delete, endpoint_url, url_payload, callback, timeout))
  end

  # Make multiple async API calls, and wait for all of them to finish.
  # params_array consists of array of RequestParams class instances, initialized with the request parameters.
  # New up a RequestParams class instances with all the params for each request, and add to the parameter array, as shown in example below
  # For eg: params_array << RequestParams.new(:get, "https://api.ls.com/plaid/v1/get", "user_id=1234&user_type=borrower", method(:process_get), 30)
  #         params_array << RequestParams.new(:post, "https://api.ls.com/plaid/v1/retrieve-report", "{}")
  # responses array is an array of hash [{ :request => request_params, :response => response_object }, ...]
  # responses array returns the responses in the same order as the requests passed in the params_array
  def self.call_multi_async_wait_all(params_array)
    threads = []
    responses = []
    params_array.each { |params|
      responses << { :request => params, :response => nil }
    }
    params_array.each { |params|
      index = params_array.index(params)
      threads << call_async_add_to_response(params, responses, index)
    }
    threads.each(&:join)
    return responses
  end

  private

  def self.call_async_add_to_response(request_params, response_array = nil, response_array_index = nil)
    user_id = DistributedTracking.user_id
    tracking_id = DistributedTracking.x_request_id
    t = Thread.new do
      Timeout::timeout(request_params.timeout) {
        begin
          begin
            if request_params.method == :get || request_params.method == :delete
              full_url = payload_to_url(request_params.url, request_params.payload)
              payload = ""
            else
              full_url = request_params.url
              payload = request_params.payload
            end
            response = rest_client_execute(request_params.method, full_url, payload, tracking_id, user_id)
          rescue RestClient::ExceptionWithResponse => e
            response = e.response
          rescue RestClient::Exception, StandardError => e
            response = e.response
          end
          response_array[response_array_index][:response] = response if !response_array.nil?
          if request_params.callback.present? && response.code == 200
            request_params.callback.call(response)
          end
        rescue StandardError => e
          response = nil
        end
      }
    end
    return t
  end

  def self.rest_client_execute(method, url, payload, tracking_id = nil, user_id = nil)
    response = nil
    begin
      if IssueJwtToken.jwt_token.nil?
        IssueJwtToken.api_gateway_token(tracking_id, user_id)
      end
      if IssueJwtToken.jwt_token.nil?
        Rails.logger.info("Fatal error occurred while calling API endpoint [#{method} #{url}]: Error: Failed to get API auth token.")
      else
        begin
          response = execute_request(method, url, payload, tracking_id, user_id)
        rescue RestClient::ExceptionWithResponse => e
          if e.response.present?
            if e.response.code == 502
              Rails.logger.info("HTTP code #{e.response.code} returned when calling endpoint [#{method} #{url}]. Retrying 1 time.")
              response = execute_request(method, url, payload, tracking_id, user_id)
            else
              raise
            end
          else
            raise
          end
        rescue RestClient::Exception, StandardError => e
          raise
        end
      end
    rescue RestClient::ExceptionWithResponse => e
      if e.response.present?
        if e.response.code == 401
          IssueJwtToken.api_gateway_token(tracking_id, user_id)
          if IssueJwtToken.jwt_token.nil?
            Rails.logger.info("Fatal error occurred while calling API endpoint [#{method} #{url}]. Error: 401 - Failed to get API auth token.")
            raise
          else
            begin
              response = execute_request(method, url, payload, tracking_id, user_id)
            rescue RestClient::ExceptionWithResponse => e
              if e.response.code == 502
                Rails.logger.info("HTTP code #{e.response.code} returned when calling endpoint [#{method} #{url}]. Retrying 1 time.")
                response = execute_request(method, url, payload, tracking_id, user_id)
              else
                raise
              end
            rescue RestClient::Exception, StandardError => e
              raise
            end
          end
        else
          raise
        end
      else
        raise
      end
    rescue RestClient::Exception, StandardError => e
      raise
    end
    response
  end

  def self.execute_request(method, url, payload, tracking_id = nil, user_id = nil)
    begin
      tracking_id = DistributedTracking.x_request_id if tracking_id.nil?
      user_id = DistributedTracking.user_id if user_id.nil?
      response = RestClient::Request.execute(method: method, 
        url: url, 
        payload: payload, 
        headers: { content_type: "application/json", accept: "application/json", authorization: IssueJwtToken.jwt_token, x_request_id: tracking_id, user_id: user_id })
      response
    rescue RestClient::ExceptionWithResponse => e
      if e.response.present?
        if e.response.code == 404
          Rails.logger.info("HTTP code #{e.response.code} returned upon executing request for API endpoint [#{method} #{url}] with payload #{payload.present? ? payload : 'null'}.")
        else
          Rails.logger.info("HTTP error code #{e.response.code} returned upon executing request for API endpoint [#{method} #{url}] with payload #{payload.present? ? payload : 'null'}.")
        end
      end
      raise
    rescue RestClient::Exception, StandardError => e
      Rails.logger.info("Fatal unhandled exception occurred while executing request for API endpoint [#{method} #{url}] with payload #{payload.present? ? payload : 'null'}.")
      raise
    end
  end

  def self.payload_to_url(endpoint_url, url_payload)
    endpoint_url_last = endpoint_url[-1,1]
    url_payload_first = url_payload[0,1] if !url_payload.to_s.empty?
    if endpoint_url_last == "/"
      endpoint_url = endpoint_url[0...-1]
    end
    full_url = endpoint_url
    full_url +=
      if url_payload.to_s.empty?
        ""
      else
        if url_payload_first == "/"
          url_payload
        elsif endpoint_url.include?("?")
          if endpoint_url_last == "?"
            url_payload_first == "?" || url_payload_first == "&" ? url_payload[1..-1] : url_payload
          else
            "&" + (url_payload_first == "?" || url_payload_first == "&" ? url_payload[1..-1] : url_payload)
          end
        else
          (url_payload.include?("=") ? "?" : "/") + (url_payload_first == "?" || url_payload_first == "&" ? url_payload[1..-1] : url_payload)
        end
      end
    full_url
  end
end

class RequestParams
  def initialize(method, url, payload, callback = nil, timeout = 20)
    @method = method
    @url = url
    @payload = payload
    @callback = callback
    @timeout = timeout
  end

  def method
    @method
  end

  def url
    @url
  end

  def payload
    @payload
  end

  def callback
    @callback
  end

  def timeout
    @timeout
  end
end

class ApiClientConfiguration
  def self.configure
    $jwt_token_url = Rails.application.credentials[Rails.env.to_sym][:jwt][:jwt_token_url]
    $jwt_token_email = Rails.application.credentials[Rails.env.to_sym][:jwt][:jwt_token_email]
    $jwt_token_password = Rails.application.credentials[Rails.env.to_sym][:jwt][:jwt_token_password]
    $api_key_base = Rails.application.credentials[:api_key_base]
    $issuer_name = Rails.application.credentials[:issuer_name]
    $client = Rails.application.credentials[:client]
    $crypto_key = Rails.application.credentials[:crypto_key]
    $uid = Rails.application.credentials[Rails.env.to_sym][:uid].to_s
    
    $jwt_token_url = ENV['JWT_TOKEN_URL'] if $jwt_token_url.nil?
    $jwt_token_email = ENV['JWT_TOKEN_EMAIL'] if $jwt_token_email.nil?
    $jwt_token_password = ENV['JWT_TOKEN_PASSWORD'] if $jwt_token_password.nil?
    $api_key_base = ENV['API_KEY_BASE'] if $api_key_base.nil?
    $issuer_name = ENV['ISSUER_NAME'] if $issuer_name.nil?
    $client = ENV['CLIENT'] if $client.nil?
    $crypto_key = ENV['CRYPTO_KEY'] if $crypto_key.nil?
    $uid = ENV['UID'] if $uid.nil?
  end
end