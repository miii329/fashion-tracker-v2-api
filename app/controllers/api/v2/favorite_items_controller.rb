class Api::V2::FavoriteItemsController < ApplicationController
  before_action :require_authentication
  before_action :set_favorite_item, only: [ :show, :update, :destroy ]

  # POST /api/v2/favorite_items/preview
  def preview
    url = params[:url].to_s.strip
    if url.blank?
      render json: { errors: [ "url is required" ] }, status: :unprocessable_entity
      return
    end

    render json: OgpService.fetch_all(url)
  end

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
    @favorite_item = Current.user.favorite_items.new(favorite_item_attributes)

    if @favorite_item.save
      render json: @favorite_item, status: :created
    else
      render json: { errors: @favorite_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v2/favorite_items/:id
  def update
    if @favorite_item.update(favorite_item_attributes)
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
      :url,
      :image_url
    ])
  end

  def favorite_item_attributes
    attrs = favorite_item_params.to_h

    if attrs["url"].present?
      preview_data = OgpService.fetch_all(attrs["url"])

      attrs["image_url"] = preview_data[:image_url] if attrs["image_url"].blank? && preview_data[:image_url].present?
      attrs["price"] = preview_data[:price] if attrs["price"].blank? && preview_data[:price].present?

      if item_name_needs_enrichment?(attrs["item_name"])
        product_name = preview_data[:item_name] || preview_data[:name]
        attrs["item_name"] = product_name if product_name.present?
      end
    end

    attrs
  rescue StandardError => error
    Rails.logger.warn("FavoriteItemsController: enrichment failed - #{error.message}")
    favorite_item_params.to_h
  end

  def item_name_needs_enrichment?(item_name)
    return true if item_name.blank?

    normalized = item_name.strip
    normalized.match?(/\A[A-Z0-9-]+(?:\s+[A-Z0-9-]+){0,2}\z/)
  end
end
