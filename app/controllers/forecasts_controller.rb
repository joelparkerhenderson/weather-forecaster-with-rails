class ForecastsController < ApplicationController

  def show
    session[:address] = params[:address]
  end

end
