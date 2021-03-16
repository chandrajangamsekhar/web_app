class AdminEnumOptions
  class << self
    if !$all_enums.present?
      $all_enums = JSON.parse(ApiClient.get("#{$enum_api_url}/get_enums", nil, "service_startup"))["response"].collect { |enum| [{enum["display_name"] => enum["code"]}, enum["enum_name"]] }
    end

    enums = $all_enums.group_by {|x| x[1]}
    enums.each do |key, value|
      group_of_enums = enums[key].collect{|v| v[0]}.reduce({},:merge)
      group_of_enums.each do |k,v|
        define_method :"#{key}_#{k}" do
          k
        end
      end
    end
  end

  def self.customer_type_borrower
    'borrower'
  end

  def self.customer_type_coborrower
    'coborrower'
  end

  def initialize(field_name)
    enums = Rails.cache.read(field_name)
    if enums.blank?
      enums = JSON.parse(ApiClient.get("#{$enum_api_url}/get_enums", nil, "service_startup"))["response"].collect { |enum| [{enum["code"] => enum["display_name"]}, enum["enum_name"]] }
      enums = enums.group_by {|x| x[1]}
      enums.each do |key, value|
        group_of_enums = enums[key].collect{|v| v[0]}.reduce({},:merge)
        Rails.cache.write(key, group_of_enums)
      end
    end
  end

  def self.enum_by_field(field_name)
    if field_name == "state_code"
      field_name = "state"
    end
    if field_name == "event"
      field_name = "income_expense_event"
    end
    self.new(field_name)
    Rails.cache.read(field_name)
  end
end

