class FileIssue < Sequel::Model
  include ASModel
  corresponds_to JSONModel(:file_issue)
  set_model_scope :global

  include MAPModel
  map_table :file_issue

  include FileIssueHelpers

  # We'll spawn these from file issue requests, so skip over any attributes that
  # we don't have.
  self.strict_param_setting = false

  STATUS_FILE_ISSUE_INITIATED = 'INITIATED'
  STATUS_RETRIEVAL_IN_PROGRESS = 'IN_PROGRESS'
  STATUS_FILE_ISSUE_ACTIVE = 'ACTIVE'
  STATUS_FILE_ISSUE_COMPLETE = 'COMPLETE'


  def update_from_json(json, opts = {}, apply_nested_records = true)
    # The status of a transfer is determined by its checklist.  Make sure the
    # status is up-to-date prior to save.

    checklist_items = [
      :checklist_submitted,
      :checklist_retrieval_started,
      :checklist_dispatched,
      :checklist_summary_sent,
      :checklist_completed,
    ]

    corresponding_status = [
      STATUS_FILE_ISSUE_INITIATED,
      STATUS_RETRIEVAL_IN_PROGRESS,
      STATUS_FILE_ISSUE_ACTIVE,
      STATUS_FILE_ISSUE_ACTIVE,
      STATUS_FILE_ISSUE_COMPLETE,
    ]

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

    # Update the items table to reflect the latest types
    MAPDB.open do |mapdb|
      json[:requested_representations].each do |item|
        mapdb[:file_issue_item]
          .filter(id: item['id'])
          .filter(file_issue_id: self.id)
          .update(dispatch_date: item['dispatch_date'],
                  dispatched_by: item['dispatched_by'],
                  expiry_date: item['expiry_date'],
                  returned_date: item['returned_date'],
                  received_by: item['received_by'])
      end
    end

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
        mapdb[:agency_location].filter(:agency_id => objs.map(&:agency_id)).map {|row| [row[:agency_id], row[:name]]}.to_h

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
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, nil)

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
            'dispatched_by' => item[:dispatched_by],
            'expiry_date' => item[:expiry_date],
            'returned_date' => item[:returned_date],
            'received_by' => item[:received_by],
            'overdue' => item_is_overdue?(item),
          }
        }

        json['file_issue_request'] = {'ref' => JSONModel(:file_issue_request).uri_for(obj.file_issue_request_id)}

        json['title'] = "%s: %s" % [obj.issue_type, Time.at(obj.create_time).to_s]
      end
    end

    jsons
    end

  def self.item_is_overdue?(item)
    return false if item[:returned_date]
    return false unless item[:dispatch_date]
    return false unless item[:expiry_date]

    item[:expiry_date] < Date.today
  end

end
