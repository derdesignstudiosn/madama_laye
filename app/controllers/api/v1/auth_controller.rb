module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:signup, :login]

      def signup
        user = User.new(signup_params)
        user.phone_number = normalize_phone(user.phone_number)
        user.role = params[:role] || :client

        if user.save
          token = JwtService.encode(user_id: user.id, role: user.role)
          render json: {
            success: true,
            message: "Compte créé avec succès",
            data: {
              user: user_response(user),
              token: token
            }
          }, status: :created
        else
          render_error("Erreur lors de la création du compte", :unprocessable_entity, user.errors.full_messages)
        end
      end

      def login
        phone = normalize_phone(params[:phone_number])
        user = User.find_by(phone_number: phone)

        if user&.authenticate(params[:password])
          token = JwtService.encode(user_id: user.id, role: user.role)
          render json: {
            success: true,
            message: "Connexion réussie",
            data: {
              user: user_response(user),
              token: token
            }
          }
        else
          render_error("Numéro de téléphone ou mot de passe incorrect", :unauthorized)
        end
      end

      private

      def signup_params
        params.permit(:phone_number, :password, :password_confirmation, :first_name, :last_name, :address, :latitude, :longitude, :avatar)
      end

      def user_response(user)
        {
          id: user.id,
          phone_number: user.phone_number,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          address: user.address,
          latitude: user.latitude,
          longitude: user.longitude,
          avatar: user.avatar,
          status: user.status,
          balance: user.balance
        }
      end

      def normalize_phone(raw)
        return raw if raw.blank?
        cleaned = raw.strip.gsub(/[\s\-\+]/, '')
        cleaned.start_with?('221') ? cleaned : "221#{cleaned}"
      end
    end
  end
end
