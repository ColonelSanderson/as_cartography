require_relative '../mapdb'

module MAPModel
  def self.included(base)
    base.extend(ClassMethods)

    if base.ancestors.include?(ASModel)
      base.include(ASModelCompat)
      base.external_system_name = 'MAP'
    end
  end

  module ClassMethods
    def map_table(table_sym)
      map_model_clz = self

      MAPDB.connected_hook do
        map_model_clz.set_dataset(MAPDB.pool[table_sym])
      end
    end
  end

end
