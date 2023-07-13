# POS and Inventory app

require 'sinatra'
require 'tilt/erubis'
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

get '/' do
  erb :home, layout: :layout
end

get '/invoice/new' do
  erb :new_invoice, layout: :layout
end

get '/customer/new' do
  erb :new_customer, layout: :layout
end

get '/item/new' do
  erb :new_item, layout: :layout
end

get '/item/add' do
  erb :add_item, layout: :layout
end