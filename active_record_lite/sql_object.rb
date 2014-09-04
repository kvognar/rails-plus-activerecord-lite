require_relative 'db_connection'
require_relative './searchable'
require_relative './associatable'
require 'active_support/inflector'

class SQLObject
  extend Searchable
  extend Associatable
    
  def self.columns
    return @columns if @columns
    query_results = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    @columns = query_results.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      
      define_method(column) do
        attributes[column]
      end
      define_method("#{column}=") do |arg|
        attributes[column] = arg
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.pluralize.underscore
  end

  def self.all
    query = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    self.parse_all(symbolized(query))
  end

  def self.parse_all(results)
    results.map { |result_hash| self.new(result_hash) }
  end

  def self.find(id)
    query = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = ?
    SQL
    self.parse_all(symbolized(query)).first

  end
  
  def self.symbolized(query)
    query.map do |result|
      result.map { |col_name, value| [col_name.to_sym, value] }
    end
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    
    col_names = self.class.columns.join(', ')
    question_marks = (["?"] * self.class.columns.count).join(', ')
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    
    self.send('id=', DBConnection.last_insert_row_id)
    
  end

  def initialize(params = {})
    params.each do |key, value|
      key = key.to_sym
      if self.class.columns.include?(key)
        self.send("#{key}=", value)
      else
        raise "unknown attribute '#{key}'"
      end
    end
  end

  def save
    self.send(:id).nil? ? insert : update
  end

  def update
    set_clause = self.class.columns.map do |column|
      "#{column} = ?"
    end.join(', ')
    
    DBConnection.execute(<<-SQL, *attribute_values, self.send(:id))
    UPDATE
      #{self.class.table_name}
    SET
      #{set_clause}
    WHERE
      id = ?
    SQL
    
  end

  def attribute_values
    self.class.columns.map { |col_name| self.send(col_name) }
  end
  
end
