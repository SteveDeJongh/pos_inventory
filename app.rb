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

def new_customer_name_validation(name, existing_names)
  if name.nil?
    "Please enter a valid name."
  elsif !(1..100).cover?(name.length)
    "Name must be less that 100 characters."
  elsif existing_names.any? { |x| x.downcase == name.downcase }
    "#{name} already exists!"
  end
end

def new_item_validation(new_item, existing_items)
  if existing_items.any? { |info| info == new_item[0] }
    "That sku already exists!"
  elsif existing_items.any? { |info| info == new_item[1] }
    "That product name already exists!"
  elsif new_item[2].to_i.to_s != new_item[2]
    "Cost must be an integer!"
  elsif new_item[3].to_i.to_s != new_item[3]
    "Retail must be an integer!"
  elsif new_item[2] > new_item[3]
    "Retail must be higher than cost."
  end
end

def exists?(item, all_items)
  if !all_items.include?(item)
    "No matching item found."
  end
end

get '/' do
  @stock = @storage.all_items.values
  erb :home, layout: :layout
end

get '/invoice/new' do
  erb :new_invoice, layout: :layout
end

get '/customer/new' do
  erb :new_customer, layout: :layout
end

post '/customer/new' do
  existing_customers = @storage.all_customers
  # binding.pry
  @name = params[:customer_name]
  error = new_customer_name_validation(@name, existing_customers)
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

post '/item/new' do
  existing_items = @storage.all_items.values.flatten
  @data = [params[:sku], params[:name], params[:cost], params[:retail]]

  error = new_item_validation(@data, existing_items)
  
  if error
    session[:error] = error
    redirect '/item/new'
  else
    @storage.add_item(@data)
    session[:success] = "Product created for #{@data[2]}."
    redirect '/'
  end
end

get '/item/add' do
  erb :add_item, layout: :layout
end


post '/item/add' do
  item = params[:item_name]
  quantity = params[:quantity].to_i
  id = @storage.find_id(item).values.flatten

  if id.empty?
    session[:error] = "No matching product found."
    redirect '/item/add'
  elsif quantity <= 0
    session[:error] = "Quantity must be 1 or greater."
    redirect '/item/add'  
  else
    @storage.add_stock(id[0].to_i, quantity)
    session[:success] = "Stock added to #{item}."
    redirect '/'
  end
end

post '/sortitems' do
  session[:sort_order] = params[:sort_order]
  redirect '/'
end

# not_found do
#   "Ruh roh, that wasn't found!"
# end

helpers do
  def sort_items(items)
    sortindex = case session[:sort_order]
                  when 'id' then 0
                  when 'sku' then 1
                  when 'description' then 2
                  when 'cost' then 3
                  when 'retail' then 4
                  when 'stock' then 5
                  when 'sold' then 6
                end
    items.sort_by { |item| item[sortindex]}
  end

  def items_in_rows(items)
    sort_items(items).map do |row|
      "<tr>
        <td>#{row[0]}</td>
        <td>#{row[1]}</td>
        <td>#{row[2]}</td>
        <td>#{row[3]}</td>
        <td>#{row[4]}</td>
        <td>#{row[5]}</td>
        <td>#{row[6]}</td>
      </tr>"
    end.join
  end

  def product_names

  end
end