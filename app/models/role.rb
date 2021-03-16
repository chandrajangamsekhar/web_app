class Role < ApplicationRecord
	has_many :permissions
	has_many :users
  attr_accessor :is_destroy
  
  def as_json(*)
    super.tap do |hash|
      hash["number_of_users"] = users.count
    end
  end

  def self.default_permissions
  	Permission.where(role_id: nil, user_id: nil)
  end

  def permissions_hash
  	h = {}
  	permissions.group_by(&:subject_class).each do |key,arr|
  		h[key] = arr.collect{ |c| c.action }
  	end
  	h
  end
end
