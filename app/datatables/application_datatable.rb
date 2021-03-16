class ApplicationDatatable
  delegate :params, to: :@view
  delegate :link_to, to: :@view
  include ActionView::Helpers::TagHelper

  def initialize(view)
    @view = view
    @total_count = 0
    @filtered_count = 0
  end

  def as_json(options = {})
    {
      data: data,
      recordsTotal: count,
      recordsFiltered: total_entries,
    }
  end

  def view_tag
    content_tag(:i, "", class: "fa fa-eye")
  end

  def edit_tag
    content_tag(:i, "", class: "fa fa-pencil-square-o")
  end

  def delete_tag
    content_tag(:i, "", class: "fa fa-trash-o")
  end

  def resend_tag
    content_tag(:i, "", class: "fa fa-repeat")
  end

  private

  def page
    params[:start].to_i / per_page + 1 if params[:start].present?
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10 if params[:length].present?
  end

  def sort_column
    params[:order].present? ? columns[params[:order]['0'][:column].to_i][0] : 0
  end

  def sort_direction
    params[:order]['0'][:dir] == "desc" ? "desc" : "asc" if params[:order].present?
  end

  def search_filter
    search_string = []
    search_integer = []
    search_array = []
    search_value_string = (params[:search].present? && params[:search][:value].present?) ? params[:search][:value].gsub(/[^0-9A-Za-z |_.,@\$\+\-]/i, '') : nil
    where = nil
    if search_value_string.present?
      columns.each do |term, type|
        search_string << "#{term} ilike '%25#{search_value_string}%25'" if type == :string || type == :text
        search_integer << "#{term} = #{search_value_string}" if type == :integer || type == :decimal
      end
      search_array = search_string
      if is_numeric?(search_value_string)
        search_array = (search_string << search_integer).flatten
      end
      where = search_array.join(' or ')
    end
    where
  end

  def is_numeric?(str)
    Float(str) != nil rescue false
  end
end