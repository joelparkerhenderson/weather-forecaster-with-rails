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
