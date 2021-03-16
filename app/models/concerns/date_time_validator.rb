class DateTimeValidator < ActiveModel::Validator
  def validate(record)
    options[:fields].each do |field|
      begin
        record[field] = Date.parse(record.send("#{field}_before_type_cast").to_s, "%d/%m/%Y")
      rescue ArgumentError
        record.errors.add(field, "is invalid date")
      end 
    end 
  end 
end