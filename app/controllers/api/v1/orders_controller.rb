module Api
  module V1
    class OrdersController < ApplicationController
      before_action :set_order, only: [:show, :accept, :complete, :assign_driver, :confirm_reception, :cancel]

      def index
        orders = case current_user.role
                 when "cook"
                   current_user.orders_as_cook
                 when "delivery_driver"
                   current_user.orders_as_delivery_driver
                 else
                   current_user.orders_as_customer
                 end

        orders = orders.where(status: params[:status]) if params[:status].present?
        orders = orders.includes(:cook, :customer, :delivery_driver, :order_items)
        result = paginate(orders.order(created_at: :desc))
        render_success({ orders: result[:data].map { |o| order_response(o) }, meta: result[:meta] })
      end

      def show
        render_success(order_response(@order))
      end

      def create
        return render_error("Action réservée aux clients") unless current_user.client?

        cook = User.find(params[:cook_id])
        return render_error("Cuisinier non trouvé", :not_found) unless cook.cook?

        order = current_user.orders_as_customer.build(
          cook: cook,
          delivery_address: params[:delivery_address] || current_user.address,
          delivery_latitude: params[:delivery_latitude] || current_user.latitude,
          delivery_longitude: params[:delivery_longitude] || current_user.longitude,
          notes: params[:notes],
          status: :pending
        )

        items = params[:items]
        if items.blank?
          return render_error("Au moins un article requis")
        end

        total = 0
        items.each do |item|
          item_type = item[:item_type]
          item_id = item[:item_id]

          product = item_type.constantize.find_by(id: item_id)
          next unless product

          order_item = order.order_items.build(
            item: product,
            quantity: item[:quantity] || 1,
            unit_price: product.price
          )
          total += order_item.unit_price * order_item.quantity
        end

        order.total_amount = total

        if order.save
          render_success(order_response(order), "Commande créée avec succès", :created)
        else
          render_error("Erreur de création de commande", :unprocessable_entity, order.errors.full_messages)
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Cuisinier non trouvé", :not_found)
      end

      def accept
        return render_error("Action réservée aux cuisiniers") unless current_user.cook?
        return render_error("Commande non trouvée", :not_found) unless @order.cook_id == current_user.id

        if @order.pending?
          @order.mark_accepted!
          render_success(order_response(@order), "Commande acceptée")
        else
          render_error("La commande n'est pas en attente")
        end
      end

      def complete
        return render_error("Action réservée aux cuisiniers") unless current_user.cook?
        return render_error("Commande non trouvée", :not_found) unless @order.cook_id == current_user.id

        if @order.delivered?
          @order.mark_completed!
          render_success(order_response(@order), "Commande terminée")
        else
          render_error("La commande doit d'abord être livrée")
        end
      end

      def assign_driver
        return render_error("Action réservée aux cuisiniers") unless current_user.cook?
        return render_error("Commande non trouvée", :not_found) unless @order.cook_id == current_user.id

        driver = User.find_by(id: params[:delivery_driver_id])
        return render_error("Livreur non trouvé", :not_found) unless driver&.delivery_driver?

        @order.assign_delivery_driver!(driver)
        render_success(order_response(@order), "Livreur assigné — en attente d'acceptation")
      end

      def accept_delivery
        return render_error("Action réservée aux livreurs") unless current_user.delivery_driver?
        return render_error("Commande non trouvée", :not_found) unless @order.delivery_driver_id == current_user.id

        if @order.driver_assigned?
          @order.accept_delivery!
          render_success(order_response(@order), "Mission acceptée")
        else
          render_error("Action impossible")
        end
      end

      def confirm_reception
        return render_error("Action réservée aux cuisiniers") unless current_user.cook?
        return render_error("Commande non trouvée", :not_found) unless @order.cook_id == current_user.id

        @order.update(client_received: true)
        render_success(order_response(@order), "Réception confirmée par le client")
      end

      def cancel
        if @order.customer_id == current_user.id || @order.cook_id == current_user.id
          if @order.pending?
            @order.cancel!
            render_success(nil, "Commande annulée")
          else
            render_error("Impossible d'annuler une commande déjà acceptée")
          end
        else
          render_error("Non autorisé", :forbidden)
        end
      end

      def my_deliveries
        require_role(:delivery_driver)
        orders = current_user.orders_as_delivery_driver.includes(:cook, :customer, :order_items)
        result = paginate(orders.order(created_at: :desc))
        render_success({ orders: result[:data].map { |o| order_response(o) }, meta: result[:meta] })
      end

      def mark_delivered
        require_role(:delivery_driver)
        order = current_user.orders_as_delivery_driver.find(params[:id])
        order.mark_delivered!

        commission = 500
        current_user.update(balance: current_user.balance + commission)

        render_success(order_response(order), "Commande marquée comme livrée. Commission: #{commission}")
      rescue ActiveRecord::RecordNotFound
        render_error("Commande non trouvée", :not_found)
      end

      def available_for_delivery
        require_role(:delivery_driver)

        unless current_user.latitude && current_user.longitude
          return render_error("Activez votre localisation d'abord")
        end

        orders = Order.where(status: :accepted)
                      .includes(:cook, :customer, :order_items)
                      .where(
                        "earth_distance(ll_to_earth(?, ?), ll_to_earth(delivery_latitude, delivery_longitude)) <= ?",
                        current_user.latitude, current_user.longitude, 1000
                      )

        result = paginate(orders.order(created_at: :desc))
        render_success({ orders: result[:data].map { |o| order_response(o) }, meta: result[:meta] })
      end

      private

      def set_order
        @order = Order.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Commande non trouvée", :not_found)
      end

      def order_response(order)
        item_ids_by_type = {}
        order.order_items.each do |oi|
          item_ids_by_type[oi.item_type] ||= []
          item_ids_by_type[oi.item_type] << oi.item_id
        end
        items_map = {}
        item_ids_by_type.each do |type, ids|
          items_map.merge!(type.constantize.where(id: ids).pluck(:id, :name).to_h { |id, name| [id, name] })
        end

        {
          id: order.id,
          customer: { id: order.customer.id, first_name: order.customer.first_name, last_name: order.customer.last_name, phone_number: order.customer.phone_number },
          cook: { id: order.cook.id, first_name: order.cook.first_name, last_name: order.cook.last_name },
          delivery_driver: order.delivery_driver ? { id: order.delivery_driver.id, first_name: order.delivery_driver.first_name, last_name: order.delivery_driver.last_name } : nil,
          status: order.status,
          items: order.order_items.map { |oi| { id: oi.id, item_type: oi.item_type, item_id: oi.item_id, quantity: oi.quantity, unit_price: oi.unit_price.to_f, name: items_map[oi.item_id] } },
          total_amount: order.total_amount.to_f,
          delivery_address: order.delivery_address,
          delivery_latitude: order.delivery_latitude,
          delivery_longitude: order.delivery_longitude,
          notes: order.notes,
          client_received: order.client_received,
          created_at: order.created_at,
          updated_at: order.updated_at
        }
      end
    end
  end
end
