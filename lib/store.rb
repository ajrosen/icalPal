module ICalPal
  # Class representing items from the <tt>Store</tt> table
  class Store
    include ICalPal

    def [](k)
      case k
      when 'name', 'title'      # Aliases
        @self['account']

      when 'owner'              # Owner iff there is an account
        (@self['owner'] == @self['account'])? nil : @self['owner']

      else @self[k]
      end
    end

    def initialize(obj)
      super

      # Convert JSON arrays to Arrays
      @self['delegations'] = JSON.parse(obj['delegations']).sort if obj['delegations']
    end

    QUERY = <<~SQL.freeze
SELECT DISTINCT

s1.name AS account,
s1.owner_name AS owner,
s1.notes,
s1.type,

(SELECT json_group_array(name)
 FROM #{self.name.split('::').last} s2
 WHERE s2.delegated_account_owner_store_id == s1.external_id
) AS delegations

FROM #{self.name.split('::').last} s1

SQL

  end
end
