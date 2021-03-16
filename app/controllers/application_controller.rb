class ApplicationController < ApplicationWebController
  # rescue_from Exception, :with => :render_error
  skip_before_action :verify_authenticity_token
  
  before_action :authenticate_user!
  # before_action :check_authenticated_user, except: [:ping]
  before_action :configure_permitted_parameters, if: :devise_controller?


  def render_error(e)
    # you can insert logic in here too to log errors
    # or get more error info and use different templates
    if e.is_a?(ActiveRecord::RecordNotFound)
      respond_to do |format|
        @message = e.message || "Record Not found for ID-#{params[:id]}"
        @message = @message.gsub("'","").gsub("=",":")
        format.html { render template: "/errors/500", status: 404 }
        format.js { render template: "/errors/500", status: 404 }
        format.json { render json: { status: "RECORD_NOT_FOUND", response: @message }, status: 404 }
      end
     else
      Rails.logger.info("Error occurred in #{self.class.to_s} -> #{caller_locations[1].label}() method")
      render :template => "/errors/500.html.erb", :status => 404
     end
  end

  def rescue_wrapper
    begin
      yield
    rescue ValidationError => e
      Log.error("Method: execute(): " + e.inspect, e)
      respond_to do |format|
        format.html { render json: { status: "VALIDATION_ERROR", response: e.to_s }, status: 200 }
        format.json { render json: { status: "VALIDATION_ERROR", response: e.to_s }, status: 200 }
      end
    rescue ActiveRecord::RecordNotFound => e
      respond_to do |format|
        @message = e.message || "Record Not found for ID-#{params[:id]}"
        format.html { render template: "/errors/500", status: 404 }
        format.js { render template: "/errors/500", status: 404 }
        format.json { render json: { status: "RECORD_NOT_FOUND", response: @message }, status: 404 }
      end
    rescue StandardError => e
      respond_to do |format|
        format.html { render template: "/errors/500", status: 500 }
        format.js { render template: "/errors/500", status: 500 }
        format.json { render json: { status: "ERROR", response: e.to_s }, status: 500 }
      end
    end
  end

  def ping
    starttime = Time.now
    @count = User.count
    endtime = Time.now
    resptime = (endtime - starttime).in_milliseconds
    @initdt = Rails.cache.read('init_date_time')
    uuid = Rails.cache.read('uuid')
    render json: {
      web: 'Ok -- ls_admin',
      initdt: @initdt,
      uuid: uuid,
      db: @count,
      #db: "TBD *****",
      rt: resptime
    }, status: :ok
    rescue StandardError => e
      Log.error("Rescue error in Method: ls_admin ping: ", e)  
      render json: {
        status: "ERROR",
        response: e.inspect
      }, status: :bad_request          
  end

  def load_user_settings
    @user_settings = {}
    if current_user
      @user_settings = current_user.to_settings_hash
    end
  end

  protected

  def self.permission
    return name = self.name.gsub('Controller','').singularize.split('::').last.constantize.name rescue nil
  end

  def current_ability
    if current_user
      @current_ability ||= Ability.new(current_user)
    end
  end

  # #load the permissions for the current user so that UI can be manipulated
  # def load_permissions
  #   @current_permissions = current_user.permissions.collect{|i| [i.subject_class, i.action]}
  # end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
  end

  def json_with_actions(rows, add_detail, add_edit, add_delete)
    json_data = rows.as_json
    json_data.each do |json_row|
      json_row["actions"] = get_actions(rows[json_data.index(json_row)].id, add_detail, add_edit, add_delete)
    end
    json_data
  end
  
  def json_with_icon_actions(rows, add_detail, add_edit, add_delete)
    json_data = rows.as_json
    json_data.each do |json_row|
      path = request.env['PATH_INFO'].gsub(".json", "")
      json_row["id_link"] = link_to(rows[json_data.index(json_row)].id.to_s, [path, rows[json_data.index(json_row)].id.to_s].join("/"))
      json_row["deactivated_at"] = helpers.format_date_time(rows[json_data.index(json_row)].deactivated_at) rescue nil
      json_row["actions"] = get_icon_actions(rows[json_data.index(json_row)].id, add_detail, add_edit, add_delete)
    end
    json_data
  end

  def hash_with_actions(rows, add_detail, add_edit, add_delete)
    json_data = rows
    json_data.each do |json_row|
      path = request.env['PATH_INFO'].gsub(".json", "")
      json_row["id_link"] = link_to(rows[json_data.index(json_row)]["id"], [path, rows[json_data.index(json_row)]["id"]].join("/"))
      json_row["actions"] = get_icon_actions(rows[json_data.index(json_row)]["id"], add_detail, add_edit, add_delete)
    end
    json_data
  end

  def check_authenticated_admin_underwriter_user
    auth_user
    #TODO Need to remove check_authenticated_admin_underwriter_user filter from all controllers
    #redirect_to authenticated_root_path unless current_user && (current_user.admin? || current_user.underwriter?)
  end

  def check_authenticated_admin_user
    auth_user
    #TODO Need to remove check_authenticated_admin_user filter from all controllers
    #redirect_to authenticated_root_path unless current_user && current_user.admin?
  end

  def check_authenticated_user
    auth_user
  end

  private

  def auth_user
    # DistributedTracking.x_request_id
    # userid = current_user ? current_user.email.split('@')[0] : "admin-not-logged-in"
    # DistributedTracking.capture_user_id(userid)
    authenticate_user!
  end

  def get_actions(id, add_detail, add_edit, add_delete)
    path = request.env['PATH_INFO'].gsub(".json", "")
    links = []
    links << link_to('Details', [path, id.to_s].join("/")) if add_detail
    links << link_to('Edit', [path, id.to_s, "edit"].join("/")) if add_edit
    links << link_to('Delete', [path, id.to_s].join("/"), method: :delete, data: { confirm: 'Are you sure?' }) if add_delete
    links.join(" | ")
  end

  def get_icon_actions(id, add_detail, add_edit, add_delete)
    path = request.env['PATH_INFO'].gsub(".json", "")
    links = []
    links << link_to(ApplicationController.helpers.view_tag, [path, id.to_s].join("/")) if add_detail
    links << link_to(ApplicationController.helpers.edit_tag, [path, id.to_s, "edit"].join("/")) if add_edit
    links << link_to(ApplicationController.helpers.delete_tag, [path, id.to_s].join("/"), method: :delete, data: { confirm: 'Are you sure?' }) if add_delete
    links.join(" ")
  end

end
