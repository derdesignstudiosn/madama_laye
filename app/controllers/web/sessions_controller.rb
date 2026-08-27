class Web::SessionsController < WebController
  skip_before_action :authenticate_web!, only: [:new, :create]

  def new
    redirect_to "/dashboard" if logged_in?
  end

  def create
    phone = normalize_phone(params[:phone_number])
    user = User.find_by(phone_number: phone)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to "/dashboard", notice: "Bonjour #{user.first_name} !"
    else
      redirect_to "/login", alert: "Téléphone ou mot de passe incorrect"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to "/login", notice: "Déconnexion réussie"
  end
end
