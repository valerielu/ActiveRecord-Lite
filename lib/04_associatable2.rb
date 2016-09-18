require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method (name) do
      through_options = self.class.assoc_options[through_name] #owner_id
      source_options = through_options.model_class.assoc_options[source_name] #house_id
      through_value = self.send(through_name)
      value = through_value.send(source_options.foreign_key)
      result = source_options.model_class.where(source_options.primary_key => value)
      result ? result.first : nil
    end
  end
end
