require 'admin_enum_options'
module AdminLsEnums
  def self.[](enum_fields)
    Module.new do
      extend ActiveSupport::Concern
      enum_fields.each do |a|
        define_method "display_#{a}" do
          AdminEnumOptions.enum_by_field(a)["#{eval(a)}"]
        end
      end  
      included do
        enum_fields.each do |a|
          enum "#{a}": AdminEnumOptions.enum_by_field(a), _suffix: true
        end  
      end
    end
  end
end