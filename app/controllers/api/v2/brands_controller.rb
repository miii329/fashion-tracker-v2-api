module Api
  module V2
    class BrandsController < ApplicationController
      before_action :require_authentication
      before_action :set_brand, only: %i[ show update destroy ]

      # GET /api/v2/brands
      def index
        @brands = Current.user.brands
        render json: @brands
      end

      # GET /api/v2/brands/1
      def show
        render json: @brand
      end

      # POST /api/v2/brands
      def create
        @brand = Current.user.brands.new(brand_params)

        if @brand.save
          @brand.attach_ogp_image_from_url
          render json: @brand, status: :created, location: api_v2_brand_url(@brand)
        else
          render json: @brand.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v2/brands/1
      def update
        if @brand.update(brand_params)
          @brand.attach_ogp_image_from_url
          render json: @brand
        else
          render json: @brand.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v2/brands/1
      def destroy
        @brand.destroy!
        head :no_content
      end

      private

      def set_brand
        @brand = Current.user.brands.find(params.expect(:id))
      end

      def brand_params
        params.expect(brand: [ :name, :category, :url, :description ])
      end
    end
  end
end
