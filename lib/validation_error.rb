class ValidationError < StandardError
  attr_reader :message, :model_object, :errors, :send_alert
  def initialize(message=nil, model_object=nil, errors=nil, send_alert=false)
    @message = (message.nil? ? "Validation error occurred." : message)
    @send_alert = send_alert
    @model_object = model_object
    @errors = errors
    super(@message)
  end
end
