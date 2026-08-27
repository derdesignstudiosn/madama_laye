class Meal < ApplicationRecord
  belongs_to :user

  enum :day_of_week, {
    monday: 0, tuesday: 1, wednesday: 2,
    thursday: 3, friday: 4, saturday: 5, sunday: 6
  }

  enum :meal_type, {
    lunch: 0,
    dinner: 1
  }

  has_many :order_items, as: :item, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :name, :price, :day_of_week, :meal_type, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :portion_count, numericality: { greater_than: 0 }, allow_nil: true

  scope :available, -> { where(available: true) }
  scope :for_day, ->(day) { where(day_of_week: day) }
  scope :for_meal_type, ->(type) { where(meal_type: type) }

  def update_rating_cache!
    avg = reviews.average(:rating)&.round(1) || 0
    update_columns(average_rating: avg, reviews_count: reviews.count)
  end
end
