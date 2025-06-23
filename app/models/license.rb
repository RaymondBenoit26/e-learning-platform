# License model represents access control for academic terms and courses
# Each license allows a student to enroll in a specific term or course with defined restrictions
# Licenses can have different types (standard, premium, enterprise, lifetime) and expiration dates
class License < ApplicationRecord
  belongs_to :licensable, polymorphic: true

  # License access records - tracks which students have purchased this license
  has_many :license_accesses, dependent: :destroy
  has_many :students, through: :license_accesses, class_name: "User"

  has_many :payments, as: :payable, dependent: :destroy

  # License type enum - defines different tiers of access
  enum :license_type, {
    standard: "standard",
    premium: "premium",
    enterprise: "enterprise",
    lifetime: "lifetime"     # No expiration - permanent access
  }

  # Validations to ensure data integrity
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_seats, presence: true, numericality: { greater_than: 0 }
  validates :license_type, presence: true
  validates :licensable_type, presence: true, inclusion: { in: %w[Term Course] }
  validates :licensable_id, presence: true

  # Scopes for filtering licenses by status
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :available, -> { active.where("max_seats > (SELECT COUNT(*) FROM license_accesses WHERE license_id = licenses.id)") }
  scope :for_terms, -> { where(licensable_type: "Term") }
  scope :for_courses, -> { where(licensable_type: "Course") }
    scope :by_school, ->(school) {
    joins("INNER JOIN terms ON terms.id = licenses.licensable_id")
      .where(licensable_type: "Term", terms: { school_id: school.id })
  }

  # Class methods for common queries
  def self.with_revenue_for_school(school)
    by_school(school)
      .joins(:payments)
      .group("licenses.id")
      .select("licenses.*, SUM(payments.amount) as total_revenue")
  end

  def self.most_popular_for_school(school)
    by_school(school)
      .left_joins(:license_accesses)
      .group("licenses.id")
      .order("COUNT(license_accesses.id) DESC")
      .first
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "description", "price", "max_seats", "expires_at", "license_type", "licensable_type", "licensable_id", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "licensable", "license_accesses", "students", "payments" ]
  end

  # Custom Ransack scopes for complex queries
  ransacker :available_seats, formatter: proc { |v| v }, type: :numeric do |parent|
    Arel.sql("(#{parent.table[:max_seats]} - (SELECT COUNT(*) FROM license_accesses WHERE license_id = licenses.id))")
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def lifetime?
    license_type == "lifetime" || expires_at.nil?
  end

  def available_seats
    max_seats - license_accesses.count
  end

  def seats_available?
    available_seats > 0
  end

  # Display-friendly expiration date
  def valid_until_display
    if lifetime?
      "Lifetime"
    else
      expires_at&.strftime("%B %d, %Y")
    end
  end

  # Display license name with price for UI
  def name_with_price
    if price&.positive?
      "#{name} - $#{price}"
    else
      "#{name} - Free"
    end
  end

  # Get the licensable object (term or course)
  def term
    licensable if licensable_type == "Term"
  end

  def course
    licensable if licensable_type == "Course"
  end
end
