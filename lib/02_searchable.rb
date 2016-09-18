require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map {|attr_name, _| "#{attr_name} = ?"}.join(" AND ")
    inputs = params.map {|_, value| value}
    results = DBConnection.execute(<<-SQL, *inputs)
      SELECT
       *
      FROM
      #{table_name}
      WHERE
      #{where_line}
    SQL
    # return nil unless results.length > 0
    self.parse_all(results)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
