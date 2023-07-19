# POS and Inventory app

require 'sinatra'
require 'tilt/erubis'
require 'pry'

configure do
  enable :sessions
  set :erb, escape_html: true
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

def new_customer_name_validation(new_name, existing_customer_names)
  if new_name.nil?
    "Please enter a valid name."
  elsif !(1..100).cover?(new_name.length)
    "Name must be less that 100 characters."
  elsif existing_customer_names.any? { |name| name.downcase == new_name.downcase }
    "#{new_name} already exists!"
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

def sku_doesnt_exist?(item, all_items)
  return "No matching item found." unless all_items.include?(item)
end

def customer_doesnt_exist?(customer_name, all_customers)
  return "#{customer_name} not found." unless all_customers.include?(customer_name)
end

##### Routes #####

get '/' do
  @stock = @storage.all_items
  @customers = @storage.all_customers
  @invoices = @storage.all_invoices
  erb :home, layout: :layout
end

get '/invoice/new' do
  erb :new_invoice, layout: :layout
end

get '/customer/new' do
  erb :new_customer, layout: :layout
end

post '/customer/new' do
  existing_customer_names = @storage.all_customers.column_values(1)
  @name = params[:customer_name]
  error = new_customer_name_validation(@name, existing_customer_names)
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
  existing_items = @storage.all_items.flatten
  @data = [params[:sku].to_i, params[:name], params[:cost], params[:retail]]

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

get '/newinvoice' do
  erb :new_invoice, layout: :layout
end

def product_ids_array(items)
  items.map do |sku|
    if sku == ''
      next
    elsif sku_doesnt_exist?(sku.to_i, @storage.all_items.flatten)
      "No matching item found for #{sku}."
    else
      @storage.find_id_from_sku(sku)[0]['id'].to_i
    end
  end
end

def new_invoice_items_total(items)
  all_item_info = @storage.all_items_and_stock
  total_cost = 0
  total_retail = 0
  items.each do |sku|
    if sku.to_i.to_s == sku
      total_cost += all_item_info[sku.to_i][:cost]
      total_retail += all_item_info[sku.to_i][:price]
    end
  end
  [total_cost, total_retail]
end

post '/newinvoice' do
  customer_name = params[:customer_name]
  customer_id = @storage.get_customer_id(customer_name)
  items = [params[:sku1], params[:sku2], params[:sku3], params[:sku4]]
  customer_names = @storage.all_customer_names.values.flatten
  product_ids = product_ids_array(items)

  error = case
          when customer_doesnt_exist?(customer_name, customer_names)
            then "#{customer_name} not found."
          when product_ids.select { |x| x != '' && x.class != Integer && !x.nil? }[0]
            then "Product does not exist."
          when stock_error
            then "Product has not stock!"
          end
  
  if error
    session[:error] = error
    redirect '/newinvoice'
  else
    product_ids = product_ids_array(items)
    order_total = new_invoice_items_total(items)
    invoice_id = @storage.create_invoice_and_return_id(customer_id, order_total[0])
    product_ids.each do |id|
      if id.to_s.to_i == id
        @storage.add_invoice_item(invoice_id, id)
      end
    end
    session[:success] = "Invoice created."
    redirect '/'
  end
end

def invoice_totals(invoice)
  items = 0
  sum = 0
  invoice.each do |line|
    items += 1
    sum += line[3].to_i
  end
  [items, sum]
end

get '/invoice/:id/' do
  invoice_id = params[:id].to_i
  @invoice_data = @storage.retrieve_invoice(invoice_id).values
  @invoice_total = invoice_totals(@invoice_data)
  erb :view_invoice, layout: :layout
end

##### View Helpers #####

helpers do
  def sort_items(items)
    current_sort = session[:sort_order]
    sort_options = { id: 0, sku: 1, description: 2, cost: 3,
                     retail: 4, stock: 5, sold: 6 }
    sortindex = current_sort ? sort_options[current_sort.to_sym] : 1
    items.sort_by { |item| item[sortindex] }
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

  def customers_in_rows(customers)
    customers.values.map do |customer|
      "<tr>
        <td>#{customer[0]}</td>
        <td>#{customer[1]}</td>
      </tr>"
    end.join
  end

  def invoices_in_rows(invoices)
    invoices.map do |row|
      "<tr>
      <th><a href='/invoice/#{row['id']}/'> #{row['id']}</a></th>
      <th>#{row['customer']}</th>
      <th>#{row['items']}</th>
      <th>#{row['total']}</th>
      </tr>"
    end.join
  end

  def display_invoice(invoice_data, invoice_totals)
    invoice_data.map.with_index do |line, idx|
      "<tr>
      <th>#{idx + 1}</th>
      <th>#{line[2]}</th>
      <th>#{line[3]}</th>
      <tr>"
    end.join << "<tr><th>Totals</th><th>#{invoice_totals[0]}
    </th><th>#{invoice_totals[1]}</th></th>"
  end
end
