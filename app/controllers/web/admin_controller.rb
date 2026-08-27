class Web::AdminController < WebController
  before_action :authenticate_web!
  before_action -> { require_role(:admin, :supervisor) }

  def index
    @total_cooks = User.cook.count
    @total_clients = User.client.count
    @total_drivers = User.delivery_driver.count
    @total_orders = Order.count
    @pending_orders = Order.pending_orders.count
    @pending_withdrawals = Withdrawal.pending.count
    @users = User.order(created_at: :desc).limit(30)
    @recent_orders = Order.includes(:customer, :cook).order(created_at: :desc).limit(10)
  end

  def withdrawals
    @withdrawals = Withdrawal.pending.recent.includes(:user)
  end

  def validate_withdrawal
    withdrawal = Withdrawal.pending.find(params[:id])
    user = withdrawal.user

    if user.balance < withdrawal.amount
      redirect_to "/admin/withdrawals", alert: "Solde insuffisant pour valider ce retrait"
      return
    end

    user.update!(balance: user.balance - withdrawal.amount)
    withdrawal.update!(status: :validated, processed_at: Time.current)

    redirect_to "/admin/withdrawals", notice: "Retrait de #{helpers.number_to_currency(withdrawal.amount, unit: 'CFA', format: '%n %u')} validé pour #{user.full_name}"
  rescue ActiveRecord::RecordNotFound
    redirect_to "/admin/withdrawals", alert: "Retrait non trouvé"
  end
end
