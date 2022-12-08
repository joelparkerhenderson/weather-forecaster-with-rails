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
