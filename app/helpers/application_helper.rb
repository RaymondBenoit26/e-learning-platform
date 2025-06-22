module ApplicationHelper
  def current_school
    @current_school ||= current_user&.school
  end

  def content_type_color(content_type)
    case content_type&.to_s
    when "document"
      "primary"
    when "video"
      "danger"
    when "audio"
      "warning"
    when "image"
      "success"
    when "link"
      "info"
    else
      "secondary"
    end
  end

  def can_manage_content?
    return true if current_user.management?
    return true if current_user.instructor? && @course && current_user.assigned_courses.include?(@course)
    false
  end
end
