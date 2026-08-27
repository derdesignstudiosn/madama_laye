module Api
  module V1
    class ReviewsController < ApplicationController
      before_action :set_meal, only: [:create]

      def index
        reviews = Review.where(meal_id: params[:meal_id]).includes(:user).recent
        result = paginate(reviews)
        render_success({ reviews: result[:data].map { |r| review_response(r) }, meta: result[:meta] })
      end

      def create
        return render_error("Action réservée aux clients") unless current_user.client?

        review = current_user.reviews.build(
          meal: @meal,
          order_id: params[:order_id],
          rating: params[:rating],
          comment: params[:comment]
        )

        if review.save
          render_success(review_response(review), "Note ajoutée avec succès", :created)
        else
          render_error("Erreur", :unprocessable_entity, review.errors.full_messages)
        end
      end

      private

      def set_meal
        @meal = Meal.find(params[:meal_id])
      rescue ActiveRecord::RecordNotFound
        render_error("Menu non trouvé", :not_found)
      end

      def review_response(review)
        {
          id: review.id,
          user: { id: review.user.id, first_name: review.user.first_name, last_name: review.user.last_name },
          meal_id: review.meal_id,
          order_id: review.order_id,
          rating: review.rating,
          comment: review.comment,
          created_at: review.created_at
        }
      end
    end
  end
end
