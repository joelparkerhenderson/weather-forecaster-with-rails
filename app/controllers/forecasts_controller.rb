class ForecastsController < ApplicationController

  def show
    @address_default = "1 Infinite Loop, Cupertino, California"
    session[:address] = params[:address]
    if params[:address]
      begin
        @address = params[:address]
        @geocode = GeocodeService.call(@address)
        @weather_cache_key = "#{@geocode.country_code}/#{@geocode.postal_code}"
        @weather_cache_exist = Rails.cache.exist?(@weather_cache_key)
        @weather = Rails.cache.fetch(@weather_cache_key, expires_in: 30.minutes) do
          WeatherService.call(@geocode.latitude, @geocode.longitude)          
        end
      rescue => e
        flash.alert = e.message
      end
    end
  end

end
