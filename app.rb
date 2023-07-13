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

def input_name_validation(name)
  if name.nil?
    "Please enter a valid name."
  elsif !(1..100).cover?(name.length)
    "Name must be less that 100 characters."
  end
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

post '/customer/new' do
  @name = params[:customer_name]
  error = input_name_validation(@name)
  if error
    session[:error] = error
    redirect '/customer/new'
  else
    @storage.add_customer(@name)
    session[:success] = "Customer #{@name} has been created."
    redirect '/'
  end  
end

get '/item/new' do
  erb :new_item, layout: :layout
end

get '/item/add' do
  erb :add_item, layout: :layout
end