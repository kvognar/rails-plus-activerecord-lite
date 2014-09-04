class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.to_s.constantize
  end

  def table_name
    @class_name.pluralize.underscore
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name = options[:class_name] || name.to_s.capitalize
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = options[:class_name] || name.to_s.capitalize.singularize
    @foreign_key = options[:foreign_key] || "#{self_class_name.downcase.underscore}_id".to_sym
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      foreign_key = self.send(options.foreign_key)
      options.model_class.find(foreign_key)
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      foreign_key_name = options.foreign_key
      foreign_key = self.send(options.primary_key)
      options.model_class.where(foreign_key_name => foreign_key)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
  
  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      puts "through: #{through_options.table_name}, source: #{source_options.table_name}"
      query = DBConnection.execute(<<-SQL)
      SELECT
      #{source_options.table_name}.*
      FROM
      #{self.class.table_name}
      JOIN
      #{through_options.table_name}
      ON
      #{through_options.foreign_key} = 
      #{through_options.table_name}.#{through_options.primary_key}
      JOIN
      #{source_options.table_name}
      ON
      #{through_options.table_name}.#{source_options.foreign_key} = 
         #{source_options.table_name}.#{source_options.primary_key}
      WHERE
      #{self.class.table_name}.id = #{self.id}
      SQL

      source_options.model_class.parse_all(self.class.symbolized(query)).first
    end
  end
end