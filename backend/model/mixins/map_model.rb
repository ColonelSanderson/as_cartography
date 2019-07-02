require_relative '../mapdb'

module MAPModel
  def self.included(base)
    base.extend(ClassMethods)

    if base.ancestors.include?(ASModel)
      base.include(ASModelCompat)
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

  module ASModelCompat
    def [](key)
      if key == :create_time
        # MAP uses ms since epoch, but we want a Ruby timestamp.  Map it!
        epoch_time = super
        Time.at(epoch_time / 1000)
      elsif key == :user_mtime
        self[:create_time]
      elsif key == :created_by
        value = super
        "MAP user: #{value}"
      elsif key == :created_by_orig
        super(:created_by)
      elsif key == :last_modified_by
        self.modified_by
      else
        super
      end
    end

    def last_modified_by=(user)
      self.created_by ||= user
      self.modified_by = user
    end

    def user_mtime=(value)
      self.create_time ||= (value.to_f * 1000).to_i
      self.modified_time = (value.to_f * 1000).to_i
    end

    def system_mtime=(value)
      self[:system_mtime] = value
    end

    def before_create
      super

      self.create_time = java.lang.System.currentTimeMillis
    end
  end

end
