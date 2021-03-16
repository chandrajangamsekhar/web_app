class CustomersDatatable < ApplicationDatatable
  delegate :edit_customer_path, to: :@view
  delegate :customer_path, to: :@view

  def initialize(view, contract_id = nil, can_edit: true)
    super(view)
    @can_edit = can_edit
  end

  private

  def data
    model_objects
    model_objects.map do |model_object|
      [].tap do |column|
        column << link_to(model_object["id"], customer_path(model_object))
        column << model_object.username
        column << model_object.customer_type
        column << model_object.date_of_birth
        column << model_object.gender
        column << model_object.phone_number

        links = []
        links << link_to(view_tag, customer_path(model_object))
        if @can_edit
          links << link_to(edit_tag, edit_customer_path(model_object))
        end
        column << links.join(' ')
      end
    end
  end

  def count
    @total_count
  end

  def total_entries
    @filtered_count
  end

  def model_objects
    @model_objects ||= fetch_model_objects
  end

  def fetch_model_objects
    filter_arr = []
    primary_filter = "contract_id in (#{@contract_ids.join(',')})" unless @contract_ids.nil?
    filter_arr << primary_filter if primary_filter.present?
    filter_arr << search_filter if search_filter.present?
    search_clause = filter_arr.join(' and ')
    model_objects = Customer.all(search_clause, sort_column, sort_direction, page, per_page)
    model_objects
  end

  def columns
    cols = []
    cols << [ "id", :integer ]
    cols << [ "username", :string ]
    cols << [ "customer_type", :string ]
    cols << [ "date_of_birth", :string ]
    cols << [ "gender", :string ]
    cols << [ "phone_number", :string ]
    cols
  end
end