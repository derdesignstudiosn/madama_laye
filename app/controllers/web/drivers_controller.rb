class Web::DriversController < WebController
  before_action :authenticate_web!
  before_action :require_cook

  def index
    @drivers = current_user.my_drivers.active
  end

  def new
    @driver = nil
  end

  def create
    driver = User.delivery_driver.active.find_by(phone_number: params[:phone_number])
    unless driver
      redirect_to "/drivers/new", alert: "Aucun livreur trouvé avec ce numéro"
      return
    end

    relationship = current_user.cook_driver_relationships.build(driver: driver)
    if relationship.save
      redirect_to "/drivers", notice: "#{driver.full_name} ajouté comme livreur"
    else
      redirect_to "/drivers/new", alert: relationship.errors.full_messages.first
    end
  end

  def destroy
    relationship = current_user.cook_driver_relationships.find_by(driver_id: params[:id])
    unless relationship
      redirect_to "/drivers", alert: "Livreur non trouvé"
      return
    end

    driver_name = relationship.driver.full_name
    relationship.destroy
    redirect_to "/drivers", notice: "#{driver_name} retiré de votre liste"
  end

  private

  def require_cook
    redirect_to "/dashboard", alert: "Accès réservé aux cuisiniers" unless current_user.cook?
  end
end
