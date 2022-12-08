# Weather forecaster app with Ruby on Rails 


## Scope

1. Use Ruby On Rails. 

2. Accept an address as input. 

3. Retrieve forecast data for the given address. This should include, at minimum, the current temperature. Bonus points: retrieve high/low and/or extended forecast.

4. Display the requested forecast details to the user.

5. Cache the forecast details for 30 minutes for all subsequent requests by zip codes. Display indicator in result is pulled from cache.


## Set up Rails

This app is developed on a MacBook Pro M1 with macOS Ventura.


### Install asdf

I like to use the `asdf` version manager to install software such as programming languages, because `asdf` makes it easier for me to manage multiple versions, environment paths, and dependencies.

Install `asdf` version manager via `brew`:

```sh
% brew install asdf
% echo -e "\n. $(brew --prefix asdf)/asdf.sh" >> ~/.zshrc
% echo -e "\n. $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash" >> ~/.zshrc
% source ~/.zshrc
```


### Install Ruby

I like to install `ruby` using the latest version, and via `brew` and `asdf`.

To do this on the MacBook Pro M1 with macOS Ventura, the installer requires the `capstone` package library files and include files.

Set up `capstone`:

```sh
% brew install capstone
% export LDFLAGS="-L"$(brew --prefix capstone)"/lib"
% export CPPFLAGS="-I"$(brew --prefix capstone)"/include"
```

Add the `asdf` plugin:

```sh
% asdf plugin add ruby
% asdf plugin-update ruby
```

Install Ruby and use it:

```sh
% asdf install ruby latest
% asdf global ruby latest
```


### Install Rails

Install Ruby on Rails:

```sh
% gem install rails
```


### Install Google Chrome

Install Google Chrome for Ruby on Rails system tests:

```sh
% brew install google-chrome
```


## Set up the app


### Create a new app

Create a new Ruby on Rails app and test it:

```sh
% rails new forecaster --skip-activerecord
% cd forecaster
% bin/rails test
% bin/rails test:system
% bin/rails server -d
% curl http://127.0.0.1:3000
% lsof -ti:3000 | xargs kill -9
```


### Add flash

I like to use Rails flash messages to show the user notices, alerts, and the like. I use some simple CSS to make the styling easy.

Add flash messages that are rendered via a view partial:

```sh
% mkdir app/views/shared
```

Create `app/views/shared/_flash.html.erb`:

```ruby
<% flash.each do |type, message| %>
  <div class="flash flash-<% type %>">
    <%= message %>
  </div>
<% end %>
```


## Accept an address as input

We want a controller can accept an address as an input parameter. 

A simple way to test this is by saving the address in the session.


### Add faker gem

To create test data, we can use the `faker` gem, which can create fake addresses.

Edit `Gemfile` and its `test` section to add the `faker` gem:

```ruby
gem "faker"
```

Run:

```sh
bundle
```


### Generate forecasts controller

Generate a forecasts controller and its tests:

```sh
% bin/rails generate controller forecasts show
```

Write a test in `test/controllers/forecasts_controller_test.rb`:

```ruby
require "test_helper"

class ForecastControllerTest < ActionDispatch::IntegrationTest

  test "show with an input address" do
    address = Faker::Address.full_address
    get forecasts_show_url, params: { address: address }
    assert_response :success
    assert_equal address, session[:address]
  end

end
```

Generate a system test that will launch the web page, and provide the correct placeholder for certain future work:

```
% bin/rails generate system_test forecasts
```

Write a test in `test/system/forecasts_test.rb`:

```ruby
require "application_system_test_case"

class ForecastsTest < ApplicationSystemTestCase

  test "show" do
    address = Faker::Address.full_address
    visit url_for \
      controller: "forecasts", 
      action: "show", 
      params: { 
        address: address 
      }
    assert_selector "h1", text: "Forecasts#show"
  end

end
```

TDD should fail:

```sh
% bin/rails test:all
```

Implement in `app/controllers/forecasts_controller.rb`:


```ruby
class ForecastsController < ApplicationController

  def show
    session[:address] = params[:address]
  end

end
```

TDD should succeed:

```sh
% bin/rails test:all
```


### Set the root path route

Edit `config/routes.rb`:

```ruby
# Defines the root path route ("/")
root "forecasts#show"
```



## Get forecast data for the given address

There are many ways we could get forecast data. 

* We choose to convert the address to a latitude and longitude, by using the geocoder gem and the ESRI ArcGIS API available [here](https://developers.arcgis.com/sign-up/)

* We choose to send the latitude and longitude to the OpenWeatherMap API available [here](https://openweathermap.com)

* We choose to implement each API as an application service, by creating a plain old Ruby object (PORO) in the directory `app/services`

Run:

```sh
% mkdir -p {app,test}/services
% touch {app,test}/services/.keep
```


### Set ArcGIS API credentials

Edit Rails credentials:

```sh
EDITOR="code --wait"  bin/rails credentials:edit
```

Add your ArcGIS credentials by replacing these fake credentials with your real credentials:

```ruby
arcgis_api_user_id: alice
arcgis_api_secret_key: 6d9ecd1c-2b00-4a0e-89d7-8f250418a9c4
```


### Add Geocoder gem

Ruby has an excellent way to access the ArcGIS API, by using the Geocoder gem, and configuring it for the ArcGIS API.

Edit `Gemfile` to add:

```ruby
# Look up a map address and convert it to latitude, longitude, etc.
gem "geocoder"
```

Run:

```sh
bundle
```


### Configure Geocoder

Create `config/initializers/geocoder.rb`:

```ruby
Geocoder.configure(
    esri: {
        api_key: [
            Rails.application.credentials.arcgis_api_user_id, 
            Rails.application.credentials.arcgis_api_secret_key,
        ], 
        for_storage: true
    }
)
```


### Create GeocodeService

We want to create a geocode service that converts from an address string into a latitude, longitude, country code, and postal code.

Create `test/services/geocode_service_test`:

```ruby
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
```

Create `app/services/geocode_service`:

```ruby
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
```


## Join OpenWeather API

Sign up at <https://openweathermap.org>

* The process creates your API key.

Example:

* OpenWeather API key: 70a6c8131f03fe7a745b6b713ed9ebfd



### Set OpenWeather API credentials

Edit Rails credentials:

```sh
EDITOR="code --wait"  bin/rails credentials:edit
```

Add your OpenWeather credentials by replacing these fake credentials with your real credentials:

```ruby
openweather_api_key: 70a6c8131f03fe7a745b6b713ed9ebfd
```


### Add Faraday gems

Ruby has many excellent ways to do HTTP API requests. I prefer the Faraday gem because it tends to provide the most power and the most capabilities, such as for asynchronous programming.

Edit `Gemfile` and add:

```ruby
# Simple flexible HTTP client library, with support for multiple backends.
gem "faraday"
gem "faraday_middleware"
```

Run:

```sh
bundle
```


### Create WeatherService

Create `test/services/weather_service_test.rb`:

```ruby
require 'test_helper'

class WeatherServiceTest < ActiveSupport::TestCase

  test "call with known parameters" do
    # Example address is 1 Infinite Loop, Cupertino, California
    latitude = 37.331669
    longitude = -122.030098 
    weather = WeatherService.call(latitude, longitude)
    assert_includes -4..44, weather.temperature
    assert_includes -4..44, weather.temperature_min
    assert_includes -4..44, weather.temperature_max
    assert_includes 0..100, weather.humidity
    assert_includes 900..1100, weather.pressure
    refute_empty weather.description
  end

end
```

Create `app/services/weather_service.rb`:

```ruby
class WeatherService
    
  def self.call(latitude, longitude)
    conn = Faraday.new("https://api.openweathermap.org") do |f|
      f.request :json # encode req bodies as JSON and automatically set the Content-Type header
      f.request :retry # retry transient failures
      f.response :json # decode response bodies as JSON
    end    
    response = conn.get('/data/2.5/weather', {
      appid: Rails.application.credentials.openweather_api_key,
      lat: latitude,
      lon: longitude,
      units: "metric",
    })
    body = response.body
    body or raise IOError.new "OpenWeather response body failed"
    body["main"] or raise IOError.new "OpenWeather main section is missing"
    body["main"]["temp"] or raise IOError.new "OpenWeather temperature is missing"
    body["main"]["temp_min"] or raise IOError.new "OpenWeather temperature minimum is missing"
    body["main"]["temp_max"] or raise IOError.new "OpenWeather temperature minimum is missing"
    body["weather"] or raise IOError.new "OpenWeather weather section is missing"
    body["weather"].length > 0 or raise IOError.new "OpenWeather weather section is empty"
    body["weather"][0]["description"] or raise IOError.new "OpenWeather weather description is missing"
    weather = OpenStruct.new
    weather.temperature = body["main"]["temp"]
    weather.temperature_min = body["main"]["temp_min"]
    weather.temperature_max = body["main"]["temp_max"]
    weather.humidity = body["main"]["humidity"]
    weather.pressure = body["main"]["pressure"]
    weather.description = body["weather"][0]["description"]
    weather
  end
    
end
```


## Complete the app

In the interest of time, I'll complete the app by doing the forecasts controller and view. Use of TDD and/or step-by-step additions are shown above, so are elided below.


### Complete the forecasts controller


Complete `app/controllers/forecasts_controller`:

```ruby
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
```


### Complete the forecasts view

Complete `app/views/forecasts/show.html.erb`:


```erb
<%= render "shared/flash" %>

<h1>Forecast</h1>

<%= form_with(method: 'get', local: true) do %>
    <%= label :address, "What is your address?" %><br>
    <%= text_field_tag(:address, @address || @address_default, size: 70) %><br>
    <%= submit_tag("Lookup") %>
<% end %>

<% if defined?(@weather) %>
    <ul>
        <li>Temperature: <%= @weather.temperature %> ℃</li>
        <li>Temperature Minimum: <%= @weather.temperature_min %> ℃</li>
        <li>Temperature Maximum: <%= @weather.temperature_max %> ℃</li>
        <li>Humidity: <%= @weather.humidity %>%</li>
        <li>Pressure: <%= @weather.pressure %> millibars</li>
        <li>Description: <%= @weather.description %></li>
        <li>Is this result from the cache? <%= @weather_cache_exist %>
    </ul>
<% end %>
```

Update `test/system/forecasts_test.rb`:

```ruby
assert_selector "h1", text: "Forecast"
```
