class Customer < TablelessApplicationRecord

  has_no_table :database => :pretend_success

  column :id, :integer
  column :username, :string
  column :customer_type, :string
  column :date_of_birth, :date
  column :gender, :string
  column :phone_number, :string
  column :created_at, :date
  column :updated_at, :date

  def self.create(params)
    payload = params.to_json
    response = ApiClient.post("#{model_api_url}", payload)
    self.new.build_model(response)
  end

  def update(params)
    payload = params.to_json
    response = ApiClient.patch("#{model_api_url}/#{self.id}", payload)
    build_model(response)
  end
end
