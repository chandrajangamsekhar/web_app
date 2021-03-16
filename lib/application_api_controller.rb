class ApplicationApiController < ActionController::API
  include ActionController::MimeResponds
  require 'json'
  require 'validation_error'
  
  def append_info_to_payload(payload)
    super
    payload[:tracking_id] = request.headers['x-request-id'].present? ? DistributedTracking.capture_x_request_id(request.headers['x-request-id'].gsub('-', '')) : DistributedTracking.x_request_id
    payload[:user_id] = request.headers['user-id'].present? ? DistributedTracking.capture_user_id(request.headers['user-id']) : DistributedTracking.user_id
  end

  protected
  # Validates the token and user and sets the @current_user scope
  def authenticate_request!
    Log.set_request(request)
    DistributedTracking.capture_x_request_id(request.headers['x-request-id']) if request.headers['x-request-id'].present?
    if request.headers['user-id'].present?
      DistributedTracking.capture_user_id(request.headers['user-id'])
    else
      if Rails.env.qa? || Rails.env.production?
        return invalid_user_id
      else
        DistributedTracking.capture_user_id("DEV-missing-user-id-header-in-request")
      end
    end
    if Rails.env.development?
      Log.warn("#### Rails is running in development mode and hence no token generation is needed ####")
      return true
    end
    if !payload 
      Log.error("invalid_authentication | payload : " + payload.to_s)
      return invalid_authentication
    end
    if !JsonWebToken.valid_payload(payload.first)
      Log.error("invalid_authentication | payload.first : " + payload.first.to_s)
      return invalid_authentication
    end
    load_current_user!
    if @current_user.blank?
      Log.error("invalid_authentication | @current_user : " + payload[0]['user_id'].to_s + " | " + $uid.to_s)
      return invalid_authentication
    end 
  end

  def validate_api_auth_token(api_auth_token)
    $api_auth_token = Rails.application.credentials[Rails.env.to_sym][:api_auth_token]
    $api_auth_token = ENV['API_AUTH_TOKEN'] if $api_auth_token.nil?
    if $api_auth_token.present? && $api_auth_token == api_auth_token
      return true
    else
      raise ValidationError.new("Unauthorized API endpoint access denied. This API endpoint can only be accessed via it's helper method.", true)
    end
  end

  # Returns 401 response. To handle malformed / invalid requests.
  def invalid_authentication
    Log.error("invalid_authentication")
    render json: {error: 'Invalid authentication'}, status: :unauthorized
  end

  # Returns 400 response. To handle incomplete requests without required headers.
  def invalid_user_id
    Log.error("Error: Header 'user-id' not sent in the request.")
    render json: {error: "Header 'user-id' not sent."}, status: :bad_request
  end

  def rescue_wrapper
    begin
      yield
    rescue ValidationError => e
      Log.error("Method: execute(): ", e)
      respond_to do |format|
        format.html { render json: { status: "VALIDATION_ERROR", response: { message: e.message, model_object: e.model_object, errors: e.errors } }, status: 200 }
        format.json { render json: { status: "VALIDATION_ERROR", response: { message: e.message, model_object: e.model_object, errors: e.errors } }, status: 200 }
      end
    rescue StandardError => e
      Log.error("Error occurred in #{self.class.to_s} -> #{caller_locations[1].label}() method. ", e, true)
      respond_to do |format|
        format.html { render json: { status: "ERROR", response: e.message }, status: 200 }
        format.json { render json: { status: "ERROR", response: e.message }, status: 200 }
      end 
    end
  end

  private

  # Deconstructs the Authorization header and decodes the JWT token.
  def payload
      @auth_header = JsonWebToken.decryptPayload(request.headers['Authorization'])
      @token = @auth_header.split(' ').last
      JsonWebToken.decode(@token)
    rescue StandardError => e
      Log.error("Rescue error in Method: def payload: ", e)
      nil
  end

  # Sets the @current_user with the user_id from payload
  def load_current_user!
    if payload[0]['user_id'].to_s == $uid.to_s
      @current_user = payload[0]['user_id']
    end
  end

end
