module Convert
  extend ActiveSupport::Concern

  included  do
    before_action :convert_date
    before_action :convert_currency
  end

  protected

  def currency_params
    if Rails.cache.read('float_columns').present?
      Rails.cache.read('float_columns')
    else
      Rails.application.eager_load!
      float_columns = TablelessApplicationRecord.descendants.collect{|d| d.columns.map{|c | c.name if c.type == :decimal}.uniq}.flatten.uniq.compact
      Rails.cache.write('float_columns', float_columns)
      float_columns
    end
  end

  def convert_date
    if request.method.upcase == "POST" || request.method.upcase == "PATCH"
      self.params = ActionController::Parameters.new(build_date(params.to_unsafe_h))
    end
  end

  def convert_currency
    if request.method.upcase == "POST" || request.method.upcase == "PATCH"
      self.params = ActionController::Parameters.new(build_currency(params.to_unsafe_h))
    end
  end

  def build_date(params)
    return params.map{|e| build_date(e)} if  params.is_a? Array

    return params unless params.is_a? Hash

    params.reduce({}) do |hash, (key, value)|
      regex = /\d{1,2}\/\d{1,2}\/\d{4}/
      if value.is_a? Array
        hash[key] = build_date(value)
      elsif value && (value.is_a? String) && value[regex]
        params_name = key
        # date_params = (1..3).map do |index|
        #   params.delete("#{params_name}(#{index}i)").to_i
        # end
        hash[params_name] = Date.strptime(value, "%m/%d/%Y") #Date.civil(value)
      else
        hash[key] = build_date(value)
      end
      hash
    end
  end

  def build_currency(params)
    return params.map{|e| build_date(e)} if  params.is_a? Array

    return params unless params.is_a? Hash

    params.reduce({}) do |hash, (key, value)|
      regex = /\d{1,2}\/\d{1,2}\/\d{4}/
      if value.is_a? Array
        hash[key] = build_currency(value)
      elsif value && (value.is_a? String) && currency_params.include?(key)
        params_name = key
        hash[params_name] = value.tr('$, ', '')
      else
        hash[key] = build_currency(value)
      end
      hash
    end
  end
end