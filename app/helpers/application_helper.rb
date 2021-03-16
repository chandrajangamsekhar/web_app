module ApplicationHelper

	def view_tag
    content_tag(:i, "", class: "fa fa-eye")
  end

  def refresh_tag
    content_tag(:i, "", class: "fa fa-refresh")
  end

  def save_tag
    content_tag(:i, "", class: "fa fa-check")
  end

  def plus_tag
    content_tag(:i, "", class: "fa fa-plus")
  end

  def edit_tag
    content_tag(:i, "", class: "fa fa-pencil-square-o")
  end

  def delete_tag
    content_tag(:i, "", class: "fa fa-trash-o")
  end

  def render_flash(flash)
    key = flash[0]
    value = flash[1]
    if key == "alert" || key == "error"
      str = content_tag :div, value, class: "flash alert alert-danger"
    end
    if key == "info"
      str = content_tag :div, value, class: "flash alert alert-info"
    end
    return str
  end

  def format_date_time(date)
    if date.present?
      if date.is_a? String
        # Following comparision is to check if date is in MM/DD/YYYY HH:MM:SSAM/PM +Timezone (01/01/2020 01:01:01PM +0000)
        # We need to parse Datetime otherwise
        if date.match(LOCALTIME_DATETIME_REGEX)
          parse_time_in_format = DateTime.strptime(date, "%m/%d/%Y %I:%M:%S%p %z").strftime("%d-%m-%Y %I:%M:%S%p %z")
        elsif date.length > 10
          # Considering for direct rendering. Not through the tableless_application_record
          parse_time_in_format = DateTime.parse(date).strftime("%d-%m-%Y %I:%M:%S%p %z")
        end
      else
        parse_time_in_format = date.getutc.strftime("%d-%m-%Y %I:%M:%S%p %z")
      end
      parse_time_in_format
      #Please dont remove blow lines for future change request purpose
      # date = DateTime.strptime(date, '%m/%d/%y %k:%M:%S')
      # date.to_time.in_time_zone(Time.zone).strftime("%m-%d-%Y %I:%M:%S%p")
    else
      ""
    end
  end

  def format_date(date, format_from_hash = false)
    if date && format_from_hash
      date = DateTime.parse(date).strftime("%m/%d/%Y %I:%M:%S%p")
    end

    if date.present?
      date = date.to_s
      begin
        date = Date.strptime(date, '%m/%d/%Y').strftime("%m/%d/%Y")
      rescue
        begin
          date = Date.parse(date).strftime("%m/%d/%Y")
        rescue
          date = date
        end
      end
      date
    else
      ""
    end
  end

  def parse_date(date)
    Date.strptime(date, "%m/%d/%Y")
  end

  def format_date_no_timezone(date)
    date ? date.to_time.strftime("%m/%d/%Y") : ""
  end

end
