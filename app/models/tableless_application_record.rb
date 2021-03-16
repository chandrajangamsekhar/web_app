class TablelessApplicationRecord < ActiveRecord::Base
  require 'json'

  def new_record?
    (self.id.present? ? false : true)
  end

  def persisted?
    (self.id.present? ? true : false)
  end

  def self.all(where = nil, sort_by = nil, sort_direction = nil, page_number = nil, rows_per_page = nil, filter_url = nil)
    model_objects = []
    filter_url ||= "#{model_api_url}"
    # Add filter, sorting, and paging params to url
    url = as_filter_url(filter_url, where, sort_by, sort_direction, page_number, rows_per_page)
    # Invoke the API call
    response = ApiClient.get(url, nil)
    # Check if response is successful. Checking both HTTP response code, and the status in the response payload
    if response.code == 200
      json_response = JSON.parse(response)
      json_response.each do |json_object|
        model_objects << as_model(json_object, self.new)
      end
    end
    # Return model objects array, total row count, and filtered row count
    model_objects
  end

  def self.find(id)
    # Invoke the API call with given id
    response = ApiClient.get("#{model_api_url}/#{id}", nil)
    # Check if response is successful. Checking both HTTP response code, and the status in the response payload
    if response.code == 200
      json_response = JSON.parse(response)
      model_object = as_model(json_response, self.new)
    end
    # Return model object
    model_object
  end

  def self.model_api_url
    global_string = "$#{self.name.underscore.downcase}_api_url"
    url = eval(global_string)
    url
  end

  def model_api_url
    global_string = "$#{self.class.name.underscore.downcase}_api_url"
    url = eval(global_string)
    url
  end

  def build_model(response)
    if response.code == 200 || response.code == 201
      json_response = JSON.parse(response)
      model_object = self.class.as_model(json_response, self.class.new)
      errors.each do |error|
        model_object.errors.add(error[0].to_sym, error[1].join(','))
      end
      model_object
    end
  end

  def format_date_time(date)
    if date
      date = date
    else
      ""
    end
  end

  def format_date(date)
    if date
      date = date.to_s
      date = date.to_time.in_time_zone(Time.zone).strftime("%m/%d/%Y")
      date.strftime("%m/%d/%Y")
    else
      ""
    end
  end

  def format_date_no_timezone(date)
    date ? date.to_time.strftime("%m/%d/%Y") : ""
  end

  private

  def self.as_model(json_object, model_object)
    if json_object.present?
      attrib_hash = {}
      model_object.attributes.keys.each do |key|
        if self.columns_hash["#{key}"].type.to_s == "date" && json_object["#{key}"].present?
          if json_object["#{key}"].match(DATE_REGEX)
            processed_value = Date.parse(json_object["#{key}"]).strftime("%m/%d/%Y")
          else
            processed_value = DateTime.parse(json_object["#{key}"]).strftime("%m/%d/%Y %I:%M:%S%p %z")
          end
          attrib_hash = attrib_hash.merge({ key => processed_value })
        else
          attrib_hash = attrib_hash.merge({ key => json_object["#{key}"] })
        end
      end
      model_object.assign_attributes(attrib_hash)
    end
    model_object
  end

  def self.as_filter_url(url, where, sort_by, sort_direction, page_number, rows_per_page)
    conditions = []
    if where.present?
      conditions << "where=#{where}"
    end
    if sort_by.present? && sort_direction.present?
      conditions << "sort_by=#{sort_by}"
      conditions << "sort_direction=#{sort_direction}"
    end
    if page_number.present? && rows_per_page.present?
      conditions << "page_number=#{page_number}"
      conditions << "rows_per_page=#{rows_per_page}"
    end
    if conditions.length > 0
      parameter_operator = url.include?('?') ? "&" : "?"
      url = "#{url}#{parameter_operator}#{conditions.join("&")}"
    end
    url
  end

end
