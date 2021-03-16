# Be sure to restart your server when you modify this file.

# ActiveSupport::Reloader.to_prepare do
#   ApplicationController.renderer.defaults.merge!(
#     http_host: 'example.org',
#     https: false
#   )
# end

Rails.cache.write('init_date_time', Time.now.to_s )
Rails.cache.write('uuid', SecureRandom.uuid )