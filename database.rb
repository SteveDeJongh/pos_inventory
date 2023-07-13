# POS database

require 'pg'

class Database
  def intialize
    @db = PG.connect(dbname: pos)
  end

  def disconnect
    @db.close
  end

end