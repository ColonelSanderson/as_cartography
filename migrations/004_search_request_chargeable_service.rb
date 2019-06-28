require 'db/migrations/utils'

Sequel.migration do

  up do

    now = Time.now

    units = self[:enumeration]
              .filter(:enumeration__name => 'runcorn_charge_quantity_unit')
              .left_join(:enumeration_value, :enumeration_value__enumeration_id => :enumeration__id)
              .select_hash(:enumeration_value__value, :enumeration_value__id)

    sr = self[:chargeable_service].insert(
                                           :name => 'Search Request',
                                           :description => 'Agency request for a search of records',
                                           :create_time => now,
                                           :system_mtime => now,
                                           :user_mtime => now
                                           )

    sr_item = self[:chargeable_item].insert(
                                         :name => 'Search Request Search',
                                         :description => 'Search fee',
                                         :price_cents => 1600,
                                         :charge_quantity_unit_id => units['qtr_hour'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => sr_item,
                                                :chargeable_service_id => sr,
                                                :aspace_relationship_position => 0,
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )
  end

  down do
  end

end
