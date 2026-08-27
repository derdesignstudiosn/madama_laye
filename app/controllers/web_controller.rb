class WebController < ActionController::Base
  layout "application"
  helper_method :current_user, :logged_in?

  before_action :authenticate_web!

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_web!
    unless logged_in?
      redirect_to "/login", alert: "Veuillez vous connecter"
    end
  end

  def require_role(*roles)
    unless roles.map(&:to_s).include?(current_user&.role)
      redirect_to "/", alert: "Accès non autorisé"
    end
  end

  def normalize_phone(raw)
    return raw if raw.blank?
    cleaned = raw.strip.gsub(/[\s\-\+]/, '')
    cleaned.start_with?('221') ? cleaned : "221#{cleaned}"
  end
end
