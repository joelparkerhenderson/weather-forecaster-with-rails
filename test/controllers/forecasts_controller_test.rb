require "test_helper"

class ForecastControllerTest < ActionDispatch::IntegrationTest

  test "show with an input address" do
    address = Faker::Address.full_address
    get forecasts_show_url, params: { address: address }
    assert_response :success
    assert_equal address, session[:address]
  end

end
