require 'securerandom'
require 'request_store_rails'

class DistributedTracking
  
  def self.x_request_id
    x_request_id = RequestLocals.fetch(:x_request_id) { nil }
    if x_request_id.nil?
      x_request_id = new_x_request_id
    end
    x_request_id
  end

  def self.new_x_request_id
    x_request_id = SecureRandom.uuid.gsub('-', '')
    RequestLocals.store[:x_request_id] = x_request_id
    x_request_id
  end

  def self.user_id
    user_id = RequestLocals.fetch(:user_id) { nil }
    user_id
  end

  def self.capture_x_request_id(x_request_id)
    unless x_request_id.nil?
      x_request_id = x_request_id.gsub('-', '')
      RequestLocals.store[:x_request_id] = x_request_id
    end
    x_request_id
  end

  def self.capture_user_id(user_id)
    unless user_id.nil?
      RequestLocals.store[:user_id] = user_id
    end
    user_id
  end
end