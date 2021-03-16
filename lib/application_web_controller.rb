class ApplicationWebController < ActionController::Base
  require 'json'
  require './lib/validation_error'

  def append_info_to_payload(payload)
    super
    payload[:tracking_id] = DistributedTracking.x_request_id
    userid = current_user ? "#{current_user.email.split('@')[0]}" : "user-not-logged-in"
    DistributedTracking.capture_user_id(userid)
    payload[:user_id] = DistributedTracking.user_id
  end

  protected

  def rescue_wrapper
    begin
      yield
    rescue ValidationError => e
      Log.error("Method: execute(): " + e.inspect, e)
      respond_to do |format|
        format.html { render json: { status: "VALIDATION_ERROR", response: { message: e.message, model_object: e.model_object, errors: e.errors } }, status: 200 }
        format.json { render json: { status: "VALIDATION_ERROR", response: { message: e.message, model_object: e.model_object, errors: e.errors } }, status: 200 }
      end
    rescue StandardError => e
      Log.error("Error occurred in #{self.class.to_s} -> #{caller_locations[1].label}() method", e, true)
      respond_to do |format|
        format.html { render json: { status: "ERROR", response: e.to_s }, status: 200 }
        format.json { render json: { status: "ERROR", response: e.to_s }, status: 200 }
      end 
    end
  end

  def web_rescue_wrapper
    begin
      yield
    rescue ValidationError => e
      Log.error("ValidationError occurred in #{self.class.to_s} -> #{caller_locations[1].label}() method", e)
      raise
    rescue StandardError => e
      Log.error("Error occurred in #{self.class.to_s} -> #{caller_locations[1].label}() method", e, true)
      raise
    end
  end

  def set_user_id(prefix)
    userid = current_user.present? ? "#{prefix}-#{current_user.email.split('@')[0]}" : "user-not-logged-in"
    DistributedTracking.capture_user_id(userid)
  end

end
