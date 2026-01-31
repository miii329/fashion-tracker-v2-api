class Api::V2::FavoriteItemsController < ApplicationController
  before_action :require_authentication
  before_action :set_favorite_item, only: [:show, :update, :destroy]

  # GET /api/v2/favorite_items
  def index
    @favorite_items = Current.user.favorite_items.order(created_at: :desc)
    render json: @favorite_items
  end

  # GET /api/v2/favorite_items/:id
  def show
    render json: @favorite_item
  end

  # POST /api/v2/favorite_items
  def create
    @favorite_item = Current.user.favorite_items.new(favorite_item_params)

    if @favorite_item.save
      render json: @favorite_item, status: :created
    else
      render json: { errors: @favorite_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v2/favorite_items/:id
  def update
    if @favorite_item.update(favorite_item_params)
      render json: @favorite_item
    else
      render json: { errors: @favorite_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v2/favorite_items/:id
  def destroy
    @favorite_item.destroy
    head :no_content
  end

  private

  def set_favorite_item
    @favorite_item = Current.user.favorite_items.find(params.expect(:id))
  end

  def favorite_item_params
    params.expect(favorite_item: [
      :item_name,
      :brand_name,
      :category,
      :price,
      :memo,
      :url
    ])
  end
end
