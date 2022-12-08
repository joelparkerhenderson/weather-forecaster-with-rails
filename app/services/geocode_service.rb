class GeocodeService 

  def self.call(address)
    response = Geocoder.search(address)
    response or raise IOError.new "Geocoder error"
    response.length > 0 or raise IOError.new "Geocoder is empty: #{response}"
    data = response.first.data
    data or raise IOError.new "Geocoder data error"
    data["lat"] or raise IOError.new "Geocoder latitude is missing"
    data["lon"] or raise IOError.new "Geocoder longitude is missing"
    data["address"] or raise IOError.new "Geocoder address is missing" 
    data["address"]["country_code"] or raise IOError.new "Geocoder country code is missing"
    data["address"]["postcode"] or raise IOError.new "Geocoder postal code is missing" 
    geocode = OpenStruct.new
    geocode.latitude = data["lat"].to_f
    geocode.longitude = data["lon"].to_f
    geocode.country_code = data["address"]["country_code"]
    geocode.postal_code = data["address"]["postcode"]
    geocode
  end

end
