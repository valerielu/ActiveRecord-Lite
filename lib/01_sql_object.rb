require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection::execute2(<<-SQL)
    SELECT *
    FROM #{table_name}
    SQL
    @columns.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |col_name|
      define_method("#{col_name}") do
        self.attributes[col_name]
      end
      define_method("#{col_name}=") do |value|
        self.attributes[col_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end


  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL
    parse_all(rows)
  end

  def self.parse_all(rows)
    objects = []
    rows.each do |row|
      objects << self.new(row)
    end
    objects
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{self.table_name}
      WHERE id == ?
    SQL
    return nil unless result.length > 0
    self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      known_attr = self.class.columns
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless known_attr.include?(attr_name)
      self.send("#{attr_name}=", value)
    end

    # SQLObject.all << self
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|attr_name| self.send(attr_name)}
  end

  def insert
    col_names = self.class.columns.drop(1).join(",")
    question_marks = Array.new(self.class.columns.length - 1, "?").join(",")
    new_row = DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id

    #interpolation inside string (dont put "" around them; need to take out the id column; id value use the method in last line)
  end

  def update
    columns = self.class.columns
    set_input = columns.drop(1).map {|attr_name| "#{attr_name} = ?"}.join(",")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1), attribute_values.first)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_input}
    WHERE
      id = ?
    SQL
  end

  def save
    self.id ? self.update : self.insert
  end

end
