class CookDriver < ApplicationRecord
  belongs_to :cook, class_name: "User"
  belongs_to :driver, class_name: "User"

  validates :cook_id, uniqueness: { scope: :driver_id, message: "Ce livreur est déjà enregistré" }
  validate :cook_must_be_cook
  validate :driver_must_be_delivery_driver

  private

  def cook_must_be_cook
    errors.add(:cook, "doit être un cuisinier") unless cook&.cook?
  end

  def driver_must_be_delivery_driver
    errors.add(:driver, "doit être un livreur") unless driver&.delivery_driver?
  end
end
