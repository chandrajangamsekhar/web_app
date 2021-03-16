class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :rememberable,
         :trackable, :timeoutable

  include ActionView::Helpers::UrlHelper

  def name
    Mail::Address.new(email).local.split('+').first.gsub(/[^0-9A-Za-z]/, ' ').titlecase
  end

  def permissions
   if !user_permissions.blank?
      return user_permissions
   end

   if !role.permissions.blank?
     return role.permissions
   end
   []
   #return default_permissions
  end
  
end
