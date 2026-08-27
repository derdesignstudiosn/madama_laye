class Web::DeliveriesController < WebController
  before_action :authenticate_web!
  before_action -> { require_role(:delivery_driver) }

  def index
    @available = Order.where(status: :accepted).includes(:cook, :customer)
    @my_deliveries = current_user.orders_as_delivery_driver.includes(:cook, :customer).where.not(status: [:cancelled, :completed])
  end

  def take
    @order = Order.where(status: :accepted).find(params[:id])
    @order.assign_delivery_driver!(current_user)
    redirect_to "/deliveries", notice: "Livraison prise en charge — veuillez accepter la mission"
  rescue ActiveRecord::RecordNotFound
    redirect_to "/deliveries", alert: "Commande déjà prise"
  end
end
