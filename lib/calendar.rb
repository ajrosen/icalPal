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

    QUERY = <<~SQL.freeze
SELECT DISTINCT

s1.name AS account,

c1.UUID,
c1.title AS calendar,

c1.shared_owner_name,
c1.shared_owner_address,

c1.published_URL,
c1.self_identity_email,
c1.owner_identity_email,
c1.notes,
c1.subcal_account_id,
c1.subcal_url,
c1.locale

FROM #{self.name.split('::').last} c1

JOIN Store s1 ON c1.store_id = s1.rowid

WHERE s1.disabled IS NOT 1
AND s1.display_order IS NOT -1
AND c1.flags IS NOT 519
SQL

  end
end
