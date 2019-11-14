class FileIssue < Sequel::Model
  include ASModel
  corresponds_to JSONModel(:file_issue)
  set_model_scope :global

  include MAPModel
  map_table :file_issue

  include FileIssueHelpers

  include ItemUses

  # We'll spawn these from file issue requests, so skip over any attributes that
  # we don't have.
  self.strict_param_setting = false

  STATUS_FILE_ISSUE_INITIATED = 'INITIATED'
  STATUS_FILE_ISSUE_ACTIVE = 'ACTIVE'
  STATUS_FILE_ISSUE_COMPLETE = 'COMPLETE'

  ISSUE_TYPE_DIGITAL = 'DIGITAL'
  ISSUE_TYPE_PHYSICAL = 'PHYSICAL'

  DIGITAL_DEFAULT_EXPIRY_DAYS = 14
  PHYSICAL_DEFAULT_EXPIRY_DAYS = 90

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # The status of a transfer is determined by its checklist.  Make sure the
    # status is up-to-date prior to save.

    checklist_items = [
      :checklist_submitted,
      :checklist_dispatched,
      :checklist_completed,
    ]

    corresponding_status = [
      STATUS_FILE_ISSUE_INITIATED,
      STATUS_FILE_ISSUE_ACTIVE,
      STATUS_FILE_ISSUE_COMPLETE,
    ]

    if json[:requested_representations].all?{|item| item['dispatch_date']}
      # all dispatched! so assume checklist_dispatched
      json[:checklist_dispatched] = true

      # If we're digital and everything is dispatched, then we're done
      if json[:issue_type] == ISSUE_TYPE_DIGITAL && status == STATUS_FILE_ISSUE_ACTIVE
        json[:checklist_completed] = true
      end
    end

    # Our status is determined by how many consecutive checklist items are
    # marked off.  For example, mark off the first three checklist items and you
    # get a "pending" status.

    first_uncompleted_checklist_idx = checklist_items.index {|checklist_item| !json[checklist_item]}

    status = if first_uncompleted_checklist_idx
               if first_uncompleted_checklist_idx == 0
                 # This shouldn't happen because we set the transfer to approved
                 # as a part of creating the transfer, but I'm nothing if not
                 # paranoid.
                 STATUS_FILE_ISSUE_INITIATED
               else
                 corresponding_status.fetch(first_uncompleted_checklist_idx - 1)
               end
             else
               # If all checklist items are complete, you're done!
               STATUS_FILE_ISSUE_COMPLETE
             end

    json[:status] = status

    # Set date_completed if the status is complete
    json[:date_completed] = Time.now.getlocal.strftime('%Y-%m-%d') if status == STATUS_FILE_ISSUE_COMPLETE

    # Update the items table to reflect the latest types
    json[:requested_representations].each do |item|
      if item['dispatch_date'] && item['expiry_date'].nil?
        begin
          dispatch_date = Date.parse(item['dispatch_date'])
          if self.issue_type == ISSUE_TYPE_DIGITAL
            item['expiry_date'] = (dispatch_date + DIGITAL_DEFAULT_EXPIRY_DAYS).to_s
          else
            item['expiry_date'] = (dispatch_date + PHYSICAL_DEFAULT_EXPIRY_DAYS).to_s
          end
        rescue
          # validations will pick up invalid dates
        end
      end

      # record movements
      if self.issue_type == ISSUE_TYPE_PHYSICAL
        prep_ref = JSONModel.parse_reference(item['ref'])
        repo_id = JSONModel.parse_reference(prep_ref[:repository])[:id]

        RequestContext.open(:repo_id => repo_id) do
          prep = PhysicalRepresentation[prep_ref[:id]]

          if item['dispatch_date']
            prep.move(:location => 'FIL',
                      :user => item['dispatched_by'] ? item['dispatched_by']['ref'] : nil,
                      :context => self.uri,
                      :date => item['dispatch_date'],
                      :replace => true)
          else
            prep.move(:location => 'FIL',
                      :context => self.uri,
                      :remove => true)
          end
        end

        RequestContext.open(:repo_id => repo_id) do
          prep = PhysicalRepresentation[prep_ref[:id]]

          if item['returned_date']
            prep.move(:location => 'HOME',
                      :user => item['received_by'] ? item['received_by']['ref'] : nil,
                      :context => self.uri,
                      :date => item['returned_date'],
                      :replace => true)
          else
            prep.move(:location => 'HOME',
                      :context => self.uri,
                      :remove => true)
          end
        end
      end


      self.db[:file_issue_item]
        .filter(id: item['id'])
        .filter(file_issue_id: self.id)
        .update(dispatch_date: item['dispatch_date'],
                dispatched_by: (item['dispatched_by'] || {})['ref'],
                expiry_date: item['expiry_date'],
                returned_date: item['returned_date'],
                received_by: (item['received_by'] || {})['ref'],
                not_returned: item['not_returned'] ? 1 : 0,
                not_returned_note: item['not_returned_note'])
    end

    # Create any digital file issue tokens, reusing token keys if they've
    # already been minted.
    existing_token_keys = self.db[:file_issue_token]
                            .filter(:file_issue_id => self.id)
                            .map {|row|
      [row[:aspace_digital_representation_id], row[:token_key]]
    }.to_h

    self.db[:file_issue_token].filter(:file_issue_id => self.id).delete

    json[:requested_representations].each do |item|
      parsed = JSONModel.parse_reference(item['ref'])
      next unless parsed.fetch(:type) == 'digital_representation'
      next unless item['dispatch_date'] && item['expiry_date']

      self.db[:file_issue_token].insert(
        token_key: existing_token_keys.fetch(parsed[:id]) { SecureRandom.hex },
        aspace_digital_representation_id: parsed[:id],
        file_issue_id: self.id,
        dispatch_date: Date.parse(item['dispatch_date']).to_time.to_i,
        expire_date: Date.parse(item['expiry_date']).to_time.to_i
      )
    end

    opts['modified_time'] = java.lang.System.currentTimeMillis
    opts['modified_by'] = RequestContext.get(:current_username)

    super
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    MAPDB.open do |mapdb|
      aspace_agents =
        mapdb[:agency]
          .filter(:id => objs.map(&:agency_id))
          .map {|row| [row[:id], row[:aspace_agency_id]]}
          .to_h

      agency_locations =
        mapdb[:agency_location].filter(:agency_id => objs.map(&:agency_id)).map {|row| [row[:id], {name: row[:name], delivery_address: row[:delivery_address]}]}.to_h

      file_issue_items =
        mapdb[:file_issue_item]
          .filter(Sequel.qualify(:file_issue_item, :file_issue_id) => objs.map(&:id))
          .all
          .group_by {|row| row[:file_issue_id]}

      handles =
        mapdb[:handle]
          .filter(:file_issue_id => objs.map(&:id))
          .map {|row| [row[:file_issue_id], row[:id]]}
          .to_h

      repo_id_by_item = repo_ids_for_items(file_issue_items)

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(aspace_agents.fetch(obj.agency_id))}
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, {})[:name]
        if json['delivery_location'] == 'AGENCY_LOCATION'
          json['delivery_address'] = agency_locations.fetch(obj.agency_location_id, {})[:delivery_address]
        end

        json['handle_id'] = handles.fetch(obj.id, nil)
        json['handle_id'] = json['handle_id'].to_s if json['handle_id']

        requested_representations = file_issue_items.fetch(obj.id, [])

        json['requested_representations'] = requested_representations
                                              .sort_by {|row| row[:id]}
                                              .map {|item|
          {
            'id' => item[:id],
            'ref' => JSONModel(item[:aspace_record_type].intern)
                       .uri_for(item[:aspace_record_id],
                                :repo_id => repo_id_by_item.fetch(item[:id])),
            'request_type' => item[:request_type],
            'record_details' => item[:record_details],
            'dispatch_date' => item[:dispatch_date],
            'dispatched_by' => {'ref' => item[:dispatched_by]},
            'expiry_date' => item[:expiry_date],
            'returned_date' => item[:returned_date],
            'received_by' => {'ref' => item[:received_by]},
            'overdue' => item_is_overdue?(item),
            'not_returned' => item[:not_returned] == 1,
            'not_returned_note' => item[:not_returned_note],
          }
        }

        json['file_issue_request'] = {'ref' => JSONModel(:file_issue_request).uri_for(obj.file_issue_request_id)}

        json['title'] = "FI%s%s" % [obj.issue_type[0].upcase, obj.id.to_s]
      end
    end

    jsons
  end

  def validate
    # can only set checklist_dispatched if all requested_representations have a dispatch date
    if self.checklist_dispatched == 1
      not_yet_dispatched_count = self.db[:file_issue_item]
                                   .filter(file_issue_id: self.id)
                                   .filter(dispatch_date: nil)
                                   .count
      if not_yet_dispatched_count > 0
        errors.add(:checklist, "Cannot check dispatched until all items have a dispatch date")
      end
    end

    # physical: checklist_completed is only set once all requested_representations have a returned_date
    if self.issue_type == ISSUE_TYPE_PHYSICAL && self.checklist_completed == 1
      not_yet_returned_count = self.db[:file_issue_item]
                                   .filter(file_issue_id: self.id)
                                   .filter(Sequel.&(returned_date: nil, not_returned: 0))
                                   .count
      if not_yet_returned_count > 0
        errors.add(:checklist, "Cannot check completed until all items have a returned date or marked as not returned")
      end
    end

    # expiry date required if there's a dispatch date
    requiring_expiry_date_count = self.db[:file_issue_item]
                                    .filter(file_issue_id: self.id)
                                    .filter(Sequel.~(dispatch_date: nil))
                                    .filter(expiry_date: nil)
                                    .count
    if requiring_expiry_date_count > 0
      errors.add(:requested_representations, "Expiry date is required when item has dispatch date")
    end

    # dispatch date is requird if expiry or return date is provided
    requiring_dispatch_date = self.db[:file_issue_item]
                                .filter(file_issue_id: self.id)
                                .filter(Sequel.|(Sequel.~(returned_date: nil), Sequel.~(expiry_date: nil)))
                                .filter(dispatch_date: nil)
                                .count
    if requiring_dispatch_date > 0
      errors.add(:requested_representations, "Dispatch date is required when item has expiry or returned date")
    end

    # check requested digital items have a file attached when dispatched
    if self.issue_type == ISSUE_TYPE_DIGITAL
      dispatched_digital_representations = self.db[:file_issue_item]
                                             .filter(file_issue_id: self.id)
                                             .filter(Sequel.~(dispatch_date: nil))
                                             .select(:aspace_record_id)
                                             .map {|row| row[:aspace_record_id].to_i}
                                             .uniq

      DB.open do |aspace_db|
        file_count = aspace_db[:representation_file]
                      .filter(:digital_representation_id => dispatched_digital_representations)
                      .count

          if dispatched_digital_representations.length > file_count
            errors.add(:requested_representations, "Digital items cannot be dispatched until they are linked to a file")
          end
      end
    end
  end

  def self.item_is_overdue?(item)
    return false if item[:returned_date]
    return false unless item[:dispatch_date]
    return false unless item[:expiry_date]
    return false if item[:not_returned]

    item[:expiry_date] < Date.today
  end


  def self.to_item_uses(json)
    return [] if json['issue_type'] == 'DIGITAL'

    qsa_id = QSAId.prefixed_id_for(FileIssue,
                                   JSONModel.parse_reference(json['uri'])[:id])

    json['requested_representations'].map{|rep|
      if rep['dispatch_date'] && JSONModel.parse_reference(rep['ref'])[:type] == 'physical_representation'
        JSONModel(:item_use).from_hash({
                                         'physical_representation' => {'ref' => rep['ref']},
                                         'item_use_type' => 'file_issue',
                                         'use_identifier' => qsa_id,
                                         'status' => json['status'],
                                         'used_by' => json['lodged_by'] || json['created_by'],
                                         'start_date' => rep['dispatch_date'],
                                         'end_date' => rep['returned_date'] ? rep['returned_date'] : nil,
                                       })
      end
    }.compact
  end

end
