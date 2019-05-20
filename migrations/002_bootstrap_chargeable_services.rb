require 'db/migrations/utils'

Sequel.migration do

  up do

    units = self[:enumeration]
      .filter(:enumeration__name => 'runcorn_charge_quantity_unit')
      .left_join(:enumeration_value, :enumeration_value__enumeration_id => :enumeration__id)
      .select_hash(:enumeration_value__value, :enumeration_value__id)

    now = Time.now

    fip = self[:chargeable_service].insert(
                                           :name => 'File Issue Physical',
                                           :description => 'File issue of physical items',
                                           :create_time => now,
                                           :system_mtime => now,
                                           :user_mtime => now
                                           )
    fip_pos = 0

    fid = self[:chargeable_service].insert(
                                           :name => 'File Issue Digital',
                                           :description => 'File issue of digital items',
                                           :create_time => now,
                                           :system_mtime => now,
                                           :user_mtime => now
                                           )
    fid_pos = 0


    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Search',
                                         :description => 'Search fee',
                                         :price_cents => 1600,
                                         :charge_quantity_unit_id => units['qtr_hour'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fip,
                                                :aspace_relationship_position => (fip_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fid,
                                                :aspace_relationship_position => (fid_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )

    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Retrieval',
                                         :description => 'Retrieval -- Standard',
                                         :price_cents => 1400,
                                         :charge_quantity_unit_id => units['record'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fip,
                                                :aspace_relationship_position => (fip_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fid,
                                                :aspace_relationship_position => (fid_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )

    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Delivery',
                                         :description => 'Delivery -- Standard (Tues & Thur) (no fee for delivery to QSA Reading Room)',
                                         :price_cents => 925,
                                         :charge_quantity_unit_id => units['order'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fip,
                                                :aspace_relationship_position => (fip_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )



    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Physical Urgent',
                                         :description => 'Additional fee for urgent orders (Urgent status is if required before next delivery day)',
                                         :price_cents => 3105,
                                         :charge_quantity_unit_id => units['order'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fip,
                                                :aspace_relationship_position => (fip_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )




    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Digital Scanning 1-20',
                                         :description => 'Digital copy/scanning -- (1-20 pages; 300 ppi; up to A3 size; PDF)',
                                         :price_cents => 175,
                                         :charge_quantity_unit_id => units['page'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fid,
                                                :aspace_relationship_position => (fid_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )

    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Digital Scanning 21-50',
                                         :description => 'Digital copy/scanning -- (21-50 pages; 300 ppi; up to A3 size; PDF)',
                                         :price_cents => 5855,
                                         :charge_quantity_unit_id => units['order'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fid,
                                                :aspace_relationship_position => (fid_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )


    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Digital Scanning 51-100',
                                         :description => 'Digital copy/scanning -- (51-100 pages; 300 ppi; up to A3 size; PDF)',
                                         :price_cents => 12580,
                                         :charge_quantity_unit_id => units['order'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fid,
                                                :aspace_relationship_position => (fid_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )


    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Digital Existing',
                                         :description => 'Existing digitised record -- (number of pages not relevant, retrieval fee waived)',
                                         :price_cents => 1400,
                                         :charge_quantity_unit_id => units['record'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fid,
                                                :aspace_relationship_position => (fid_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )


    item = self[:chargeable_item].insert(
                                         :name => 'File Issue Digital Urgent',
                                         :description => 'Additional fee for urgent scanning orders (Urgent status is if required before next delivery day)',
                                         :price_cents => 3105,
                                         :charge_quantity_unit_id => units['order'],
                                         :create_time => now,
                                         :system_mtime => now,
                                         :user_mtime => now
                                         )

    self[:chargeable_service_item_rlshp].insert(
                                                :chargeable_item_id => item,
                                                :chargeable_service_id => fid,
                                                :aspace_relationship_position => (fid_pos += 1),
                                                :system_mtime => now,
                                                :user_mtime => now
                                                )

  end

  down do
  end

end
