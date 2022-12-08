require 'test_helper'

class GeocodeServiceTest < ActiveSupport::TestCase

  test "call with known address" do
    address = "1 Infinite Loop, Cupertino, California"
    geocode = GeocodeService.call(address)
    assert_in_delta 37.33, geocode.latitude, 0.1
    assert_in_delta -122.03, geocode.longitude, 0.1
    assert_equal "us", geocode.country_code
    assert_equal "95014", geocode.postal_code
  end

end
