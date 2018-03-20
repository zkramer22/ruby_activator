require_relative 'db_connection'
require_relative 'searchable'
require 'active_support/inflector'

class SQLObject

  #################
  # class methods #
  #################

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(rows)
  end

  def self.columns
    return @columns if @columns
    table_info = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns = table_info[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end
    end
  end

  def self.find(id)
    rows = DBConnection.execute(<<-SQL, id)

      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
      LIMIT
        1
    SQL

    self.parse_all(rows)[0]
  end

  def self.first(n = 1)
    result = DBConnection.execute(<<-SQL)

      SELECT
        *
      FROM
        #{self.table_name}
      ORDER BY
        #{self.table_name}.id
    SQL

    return self.parse_all(result)[0] if n == 1

    self.parse_all(result)[0..(n - 1)]
  end

  def self.last(n = 1)
    result = DBConnection.execute(<<-SQL)

      SELECT
        *
      FROM
        #{self.table_name}
      ORDER BY
        #{self.table_name}.id
    SQL

    return self.parse_all(result)[-1] if n == 1

    self.parse_all(result)[-n..-1]
  end

  def self.parse_all(results)
    objects = []

    results.each do |result|
      objects << self.new(result)
    end

    objects
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    string = self.to_s.downcase
    @table_name = "#{string}s"
  end

  ####################
  # instance methods #
  ####################

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", value)
    end
  end

  def insert
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * columns.length).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def save
    self.id.nil? ? self.insert : self.update
  end

  def update
    set_line = self.class.columns
      .map { |col| "#{col} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end
end
