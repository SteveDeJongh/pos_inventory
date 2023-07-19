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

  def all_customer_names
    sql = <<~SQL
      SELECT name FROM customer;
    SQL

    query(sql)
  end

  def get_customer_id(name)
    sql = <<~SQL
      SELECT id FROM customer WHERE name = $1;
    SQL

    query(sql, name).values.flatten[0].to_i
  end

  def create_invoice_and_return_id(cust_id, total_cost)
    sql = <<~SQL
      INSERT INTO invoice (customer_id, total_cost)
      VALUES ($1, $2);
    SQL

    query(sql, cust_id, total_cost)

    sql2 = <<~SQL
      SELECT max(id) FROM invoice;
    SQL

    query(sql2).values.flatten[0]
  end

  def add_invoice_item(invoice_id, item_id)
    sql = <<~SQL
      INSERT INTO invoices_items (invoice_id, item_id)
      VALUES ($1, $2);
    SQL
    sql2 = <<~SQL
    UPDATE item SET qty = (qty - 1),
    qty_sold = (qty_sold + 1)
    WHERE id = ($1);
    SQL

    query(sql, invoice_id, item_id)
    query(sql2, item_id)
  end

  def all_items
    sql = <<~SQL
      SELECT * FROM item;
    SQL

    query(sql).map { |item| tuple_to_item_array(item) }
  end

  def all_items_and_stock
    sql = <<~SQL
      SELECT sku, cost, price FROM item;
    SQL

    result = {}

    query(sql).each do |item|
      result[item["sku"].to_i] = { cost: item["cost"].to_i,
                                   price: item["price"].to_i,
                                   stock: item["stock"].to_i }
    end
    result
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

  def find_id_from_sku(sku)
    sql = <<~SQL
      SELECT id FROM item WHERE sku = $1;
    SQL

    query(sql, sku)
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
    SELECT invoice.id, customer.name, item.description, price, item.id
    FROM invoice
    JOIN invoices_items ON invoices_items.invoice_id = invoice.id
    JOIN item ON invoices_items.item_id = item.id
    JOIN customer ON invoice.customer_id = customer.id
    WHERE invoice.id = $1;
    SQL

    query(sql, id)
  end

  def delete_invoice(invoice_id)
    sql = <<~SQL
    DELETE FROM invoices_items WHERE invoice_id = $1;
    SQL
    sql2 = <<~SQL
    DELETE FROM invoice WHERE id = $1;
    SQL
    query(sql, invoice_id)
    query(sql2, invoice_id)
  end

  def return_item_to_stock(item_ids)
    sql = <<~SQL
    UPDATE item SET qty = (qty + 1),
    qty_sold = (qty_sold - 1)
    WHERE id = ($1);
    SQL
    binding.pry
    item_ids.each do |id|
      query(sql, id)
    end
  end

  private

  def tuple_to_item_array(item)
    [item['id'].to_i, item['sku'].to_i, item['description'].capitalize,
     item['cost'].to_f, item['price'].to_f, item['qty'].to_i,
     item['qty_sold'].to_i]
  end
end
