# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PauseTypesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    # If full=true, use model_index_render for ControllerGenericIndex compatibility
    if response_full?
      model_index_render(PauseType.active.ordered, params)
    else
      # Return simple array for dropdown menus
      pause_types = PauseType.active.ordered
      render json: pause_types.map(&:attributes_with_association_ids), status: :ok
    end
  end

  def search
    model_search_render(PauseType, params)
  end

  def show
    pause_type = PauseType.find(params[:id])
    render json: pause_type.attributes_with_association_ids, status: :ok
  end

  def create
    pause_type = PauseType.new(pause_type_params)
    pause_type.created_by_id = current_user.id
    pause_type.updated_by_id = current_user.id
    pause_type.save!
    render json: pause_type.attributes_with_association_ids, status: :created
  end

  def update
    pause_type = PauseType.find(params[:id])
    pause_type.assign_attributes(pause_type_params)
    pause_type.updated_by_id = current_user.id
    pause_type.save!
    render json: pause_type.attributes_with_association_ids, status: :ok
  end

  def destroy
    pause_type = PauseType.find(params[:id])
    pause_type.destroy!
    render json: {}, status: :ok
  end

  private

  def pause_type_params
    params.permit(:name, :time_limit, :color, :active, :warning_minutes)
  end
end
