module ICalPal
  # Class representing items from the <tt>Calendar</tt> table
  class Calendar
    include ICalPal

    QUERY = <<~SQL.freeze
SELECT DISTINCT

Store.name AS account,
Calendar.title AS calendar,
*

FROM #{self.name.split('::').last}

JOIN Store ON store_id = Store.rowid

WHERE Store.disabled IS NOT 1
AND Store.display_order IS NOT -1
AND Calendar.flags IS NOT 519
SQL

  end
end
