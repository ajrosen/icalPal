module ICalPal
  # Class representing items from the <tt>Store</tt> table
  class Store
    include ICalPal

    QUERY = <<~SQL.freeze
SELECT DISTINCT

Store.name AS account,
*

FROM #{self.name.split('::').last}

WHERE Store.disabled IS NOT 1
AND Store.display_order IS NOT -1
SQL

  end
end
