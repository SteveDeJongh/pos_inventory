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

end