module Api
  module V1
    class MealsController < ApplicationController
      before_action :require_cook
      before_action :set_meal, only: [:show, :update, :destroy]

      def index
        meals = current_user.meals
        result = paginate(meals.order(day_of_week: :asc, meal_type: :asc))
        render_success({ meals: result[:data], meta: result[:meta] })
      end

      def show
        render_success(meal_response(@meal))
      end

      def create
        meal = current_user.meals.build(meal_params)

        if meal.save
          render_success(meal_response(meal), "Plat créé avec succès", :created)
        else
          render_error("Erreur de création", :unprocessable_entity, meal.errors.full_messages)
        end
      end

      def update
        if @meal.update(meal_params)
          render_success(meal_response(@meal), "Plat mis à jour")
        else
          render_error("Erreur de mise à jour", :unprocessable_entity, @meal.errors.full_messages)
        end
      end

      def destroy
        @meal.destroy
        render_success(nil, "Plat supprimé")
      end

      def available_by_day
        day = params[:day_of_week]
        meals = current_user.meals.available
        meals = meals.for_day(day) if day.present?

        render_success(meals.map { |m| meal_response(m) })
      end

      private

      def set_meal
        @meal = current_user.meals.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Plat non trouvé", :not_found)
      end

      def meal_params
        params.permit(:name, :description, :price, :day_of_week, :meal_type, :available, :portion_count)
      end

      def require_cook
        require_role(:cook)
      end

      def meal_response(meal)
        {
          id: meal.id,
          name: meal.name,
          description: meal.description,
          price: meal.price.to_f,
          day_of_week: meal.day_of_week,
          meal_type: meal.meal_type,
          available: meal.available,
          portion_count: meal.portion_count,
          average_rating: meal.average_rating_before_type_cast,
          reviews_count: meal.reviews_count,
          created_at: meal.created_at
        }
      end
    end
  end
end
