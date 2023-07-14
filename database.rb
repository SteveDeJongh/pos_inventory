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
      SELECT name FROM customer;
    SQL

    query(sql).values.flatten
  end

  def all_items
    sql = <<~SQL
      SELECT * FROM item;
    SQL

    query(sql)
  end

  def add_item(data)
    sql = <<~SQL
      INSERT INTO item (sku, description, cost, price)
      VALUES ($1, $2, $3, $4)
    SQL

    query(sql, *data)
  end
end