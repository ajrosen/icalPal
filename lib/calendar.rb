module ICalPal
  # Class representing items from the <tt>Calendar</tt> table
  class Calendar
    include ICalPal

    def [](k)
      case k
      when 'name', 'title'      # Aliases
        @self['calendar']

      else @self[k]
      end
    end

    def initialize(obj)
      super

      @self['sharees'] = JSON.parse(obj['sharees'])
    end

    QUERY = <<~SQL.freeze
SELECT DISTINCT

s1.name AS account,

c1.UUID,
c1.title AS calendar,

c1.shared_owner_name,
c1.shared_owner_address,

json_group_array(i1.display_name) AS sharees,

c1.published_URL,
c1.self_identity_email,
c1.owner_identity_email,
c1.notes,
c1.subcal_account_id,
c1.subcal_url,
c1.locale

FROM #{self.name.split('::').last} c1

JOIN Store s1 ON c1.store_id = s1.rowid
LEFT OUTER JOIN Sharee s2 ON c1.rowid = s2.owner_id
LEFT OUTER JOIN Identity i1 ON s2.identity_id = i1.rowid

WHERE s1.disabled IS NOT 1
AND s1.display_order IS NOT -1
AND c1.flags IS NOT 519

GROUP BY c1.title
SQL

  end
end
