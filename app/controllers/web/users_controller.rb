class Web::UsersController < WebController
  skip_before_action :authenticate_web!, only: [:new, :create]

  def new
    redirect_to "/dashboard" if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.phone_number = normalize_phone(@user.phone_number)
    @user.status = :active

    if @user.save
      session[:user_id] = @user.id
      redirect_to "/dashboard", notice: "Compte créé avec succès !"
    else
      @errors = @user.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:phone_number, :password, :password_confirmation, :first_name, :last_name, :address, :latitude, :longitude, :role)
  end
end
