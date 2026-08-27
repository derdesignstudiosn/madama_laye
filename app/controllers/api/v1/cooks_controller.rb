module Api
  module V1
    class CooksController < ApplicationController
      before_action :require_cook

      def drivers
        render_success(current_user.my_drivers.select(:id, :first_name, :last_name, :phone_number, :latitude, :longitude, :status))
      end

      def add_driver
        raw_phone = params[:phone_number].to_s.strip.gsub(/[\s\-\+]/, '')
        phone = raw_phone.start_with?('221') ? raw_phone : "221#{raw_phone}"

        driver = User.delivery_driver.active.find_by(phone_number: phone)
        return render_error("Aucun livreur trouvé avec ce numéro", :not_found) unless driver

        relationship = current_user.cook_driver_relationships.build(driver: driver)

        if relationship.save
          render_success({
            id: driver.id,
            first_name: driver.first_name,
            last_name: driver.last_name,
            phone_number: driver.phone_number
          }, "Livreur ajouté avec succès", :created)
        else
          render_error(relationship.errors.full_messages.first)
        end
      end

      def remove_driver
        relationship = current_user.cook_driver_relationships.find_by(driver_id: params[:id])
        return render_error("Livreur non trouvé dans votre liste", :not_found) unless relationship

        relationship.destroy
        render_success(nil, "Livreur retiré de votre liste")
      end

      private

      def require_cook
        require_role(:cook)
      end
    end
  end
end
