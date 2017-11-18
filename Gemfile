# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'sinatra'
gem 'sinatra-contrib'
gem 'redcarpet'
gem 'mysql2'
gem 'mysql2-cs-bind'
gem 'ridgepole'
gem 'capistrano', '~> 3.0'
gem 'capistrano-rbenv'
gem 'capistrano-bundler'
gem 'capistrano3-unicorn'

group :production do
  gem 'unicorn'
end

gem 'omniauth'
gem 'omniauth-slack'
gem 'pry'
