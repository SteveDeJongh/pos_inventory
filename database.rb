# POS database

require 'pg'
require 'pry'

class Database
  def initialize
    @db = PG.connect(dbname: "pos")
  end

  def disconnect
    @db.close
  end

  def query(sql, *params)
    @db.exec_params(sql, params)
  end

  def add_customer(name)
    sql = <<~SQL
      INSERT INTO customer (name)
      VALUES ($1);
    SQL
    query(sql, name)
  end

  def all_customers
    sql = <<~SQL
      SELECT * FROM customer;
    SQL

    query(sql)
  end

  def all_items
    sql = <<~SQL
      SELECT * FROM item;
    SQL

    query(sql).map { |item| tuple_to_item_array(item) }
  end

  def add_item(data)
    sql = <<~SQL
      INSERT INTO item (sku, description, cost, price)
      VALUES ($1, $2, $3, $4)
    SQL

    query(sql, *data)
  end

  def find_id(description)
    sql = <<~SQL
      SELECT id from item WHERE description = $1;
    SQL

    query(sql, description)
  end

  def add_stock(id, quantity)
    sql = <<~SQL
      UPDATE item SET qty = (qty + $2) WHERE id = $1
    SQL

    query(sql, id, quantity)
  end

  def all_invoices
    sql = <<~SQL
      SELECT invoice.id, min(customer.name) AS customer, 
        string_agg(item.description, ', ') AS items, sum(price) AS total
        FROM invoice 
        JOIN invoices_items ON invoices_items.invoice_id = invoice.id
        JOIN item ON invoices_items.item_id = item.id
        JOIN customer ON invoice.customer_id = customer.id
        GROUP BY invoice.id;
      SQL
  
    query(sql)
  end

  def retrieve_invoice(id)
    sql = <<~SQL
    SELECT invoice.id, customer.name, item.description, price
    FROM invoice 
    JOIN invoices_items ON invoices_items.invoice_id = invoice.id
    JOIN item ON invoices_items.item_id = item.id
    JOIN customer ON invoice.customer_id = customer.id
    WHERE invoice.id = $1;
    SQL

    query(sql, id)
  end

  private

  def tuple_to_item_array(item)
    [item['id'].to_i, item['sku'].to_i, item['description'].capitalize,
     item['cost'].to_f, item['price'].to_f, item['qty'].to_i,
     item['qty_sold'].to_i]
  end
end
