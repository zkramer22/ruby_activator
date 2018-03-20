require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    where_arr = params.keys.map { |key| "#{key} = ?" }

    where_line = where_arr.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    self.parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
