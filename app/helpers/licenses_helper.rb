module LicensesHelper
  def license_type_badge_class(license_type)
    case license_type
    when "standard"
      "primary"
    when "premium"
      "warning"
    when "enterprise"
      "info"
    when "lifetime"
      "success"
    else
      "secondary"
    end
  end

  def license_status_badge(license)
    if license.expired?
      content_tag :span, "Expired", class: "badge bg-danger"
    elsif license.seats_available?
      content_tag :span, "Available", class: "badge bg-success"
    else
      content_tag :span, "Full", class: "badge bg-warning"
    end
  end

  def utilization_percentage(license)
    return 0 if license.max_seats == 0
    (license.students.count.to_f / license.max_seats * 100).round(1)
  end

  def utilization_progress_class(utilization)
    return "success" if utilization <= 70
    return "warning" if utilization <= 90
    "danger"
  end

  def available_seats_class(license)
    license.available_seats > 0 ? "text-success" : "text-danger"
  end

  def license_card_border_class(license)
    "border-danger" if license.expired?
  end

  def license_expiry_class(license)
    license.expired? ? "text-danger" : "text-success"
  end

  def license_revenue(license)
    license.payments.sum(:amount)
  end

  def format_license_price(price)
    number_with_precision(price, precision: 0)
  end

  def license_type_options
    [
      [ "All Types", "" ],
      [ "Standard", "standard" ],
      [ "Premium", "premium" ],
      [ "Enterprise", "enterprise" ],
      [ "Lifetime", "lifetime" ]
    ]
  end



  def license_statistics_cards(licenses)
    [
      { count: licenses.count, label: "Total Licenses", bg_class: "bg-primary" },
      { count: licenses.active.count, label: "Active", bg_class: "bg-success" },
      { count: licenses.available.count, label: "Available", bg_class: "bg-warning" },
      { count: licenses.expired.count, label: "Expired", bg_class: "bg-danger" }
    ]
  end
end
