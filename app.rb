# POS and Inventory app

require 'sinatra'
require 'titl/erubis'
require 'pry'

configure do
  enable :sessions
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload "database.rb"
end

require_relative "database"

before do
  @storage = Database.new()
end

after do
  @storage.disconnect
end