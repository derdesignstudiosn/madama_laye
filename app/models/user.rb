class User < ApplicationRecord
  has_secure_password

  enum :role, {
    client: 0,
    cook: 1,
    delivery_driver: 2,
    admin: 3,
    supervisor: 4
  }

  enum :status, {
    active: 0,
    inactive: 1,
    suspended: 2
  }

  has_many :meals, dependent: :destroy
  has_many :daily_products, dependent: :destroy
  has_many :orders_as_customer, class_name: "Order", foreign_key: :customer_id, dependent: :destroy
  has_many :orders_as_cook, class_name: "Order", foreign_key: :cook_id, dependent: :destroy
  has_many :orders_as_delivery_driver, class_name: "Order", foreign_key: :delivery_driver_id, dependent: :nullify
  has_many :reviews, dependent: :destroy
  has_many :payments, foreign_key: :customer_id, dependent: :destroy
  has_many :withdrawals, dependent: :destroy

  has_many :cook_driver_relationships, class_name: "CookDriver", foreign_key: :cook_id, dependent: :destroy
  has_many :my_drivers, through: :cook_driver_relationships, source: :driver

  has_many :driver_cook_relationships, class_name: "CookDriver", foreign_key: :driver_id, dependent: :destroy
  has_many :cooks_i_deliver_for, through: :driver_cook_relationships, source: :cook

  validates :phone_number, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :role, presence: true
  validates :first_name, :last_name, presence: true
  geocoded_by :address
  after_validation :geocode, if: -> { address_changed? && !latitude_changed? && !longitude_changed? }

  scope :nearby_cooks, ->(lat, lng, radius_in_km = 0.5) {
    where(role: :cook, status: :active)
      .where("earth_distance(ll_to_earth(?, ?), ll_to_earth(latitude, longitude)) <= ?", lat, lng, radius_in_km * 1000)
  }

  scope :nearby_delivery_drivers, ->(lat, lng, radius_in_km = 1.0) {
    where(role: :delivery_driver, status: :active)
      .where("earth_distance(ll_to_earth(?, ?), ll_to_earth(latitude, longitude)) <= ?", lat, lng, radius_in_km * 1000)
  }

  def full_name
    "#{first_name} #{last_name}"
  end
end
