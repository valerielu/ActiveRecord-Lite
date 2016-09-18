require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.downcase + "s"#.pluralize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = "#{name}_id".to_sym
    @primary_key = :id
    @class_name = "#{name}".camelcase.singularize
    options.each do |attr_name, value|
      self.send("#{attr_name}=", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = "#{self_class_name}_id".downcase.to_sym
    @primary_key = :id
    @class_name = "#{name}".camelcase.singularize
    options.each do |attr_name, value|
      self.send("#{attr_name}=", value)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      value = self.send(options.foreign_key)
      result = options.model_class.where(options.primary_key => value)
      result ? result.first : nil
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      value = self.send(options.primary_key)
      result = options.model_class.where(options.foreign_key => value)
    end
    #the self here is the instance!!! since we defined method inside a class nethod (has_many and belongs_to), now
    #we are in an instance method.
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {} #this is a class method => stores all the belongs_to associations in this hash
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable #aren't those instance methods though???
end
