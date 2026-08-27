class Review < ApplicationRecord
  belongs_to :user
  belongs_to :meal
  belongs_to :order

  validates :rating, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :user_id, uniqueness: { scope: :meal_id, message: "Vous avez déjà noté ce menu" }

  scope :recent, -> { order(created_at: :desc) }

  after_save :update_meal_rating_cache
  after_destroy :update_meal_rating_cache

  private

  def update_meal_rating_cache
    meal.update_rating_cache!
  end
end
