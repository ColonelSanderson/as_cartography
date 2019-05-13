class Transfer < Sequel::Model

  STATUS_APPROVED = 'APPROVED'

  TRANSFER_PROCESS_INITIATED = 'TRANSFER_PROCESS_INITIATED'
  TRANSFER_PROCESS_PENDING = 'TRANSFER_PROCESS_PENDING'
  TRANSFER_PROCESS_IN_PROGRESS = 'TRANSFER_PROCESS_IN_PROGRESS'
  TRANSFER_PROCESS_COMPLETE = 'TRANSFER_PROCESS_COMPLETE'


  include ASModel
  corresponds_to JSONModel(:transfer)
  set_model_scope :global

  include MAPModel
  map_table :transfer


  def self.create_from_proposal(proposal_id)
    proposal = TransferProposal[proposal_id]

    created = self.create(:agency_id => proposal.agency_id,
                          :agency_location_id => proposal.agency_location_id,
                          :title => proposal.title,
                          :created_by => RequestContext.get(:current_username),
                          :create_time => java.lang.System.currentTimeMillis,
                          :status => TRANSFER_PROCESS_INITIATED,
                          :checklist_transfer_proposal_approved => 1,
                          :transfer_proposal_id => proposal_id,
                          :system_mtime => Time.now)

    self.db[:handle].insert(:transfer_id => created.id)

    self.db[:transfer_proposal]
      .filter(:id => proposal_id)
      .update(:status => STATUS_APPROVED)

    created
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # The status of a transfer is determined by its checklist.  Make sure the
    # status is up-to-date prior to save.

    checklist_items = [
      :checklist_transfer_proposal_approved,
      :checklist_metadata_received,
      :checklist_rap_received,
      :checklist_metadata_approved,
      :checklist_transfer_received,
      :checklist_metadata_imported,
    ]

    corresponding_status = [
      TRANSFER_PROCESS_INITIATED,
      TRANSFER_PROCESS_INITIATED,
      TRANSFER_PROCESS_PENDING,
      TRANSFER_PROCESS_PENDING,
      TRANSFER_PROCESS_IN_PROGRESS,
      TRANSFER_PROCESS_COMPLETE,
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
                 TRANSFER_PROCESS_INITIATED
               else
                 corresponding_status.fetch(first_uncompleted_checklist_idx - 1)
               end
             else
               # If all checklist items are complete, you're done!
               TRANSFER_PROCESS_COMPLETE
             end

    json[:status] = status

    # Update the file table to reflect the latest types
    json[:files].each do |file|
      self.db[:transfer_file].filter(:key => file['key']).update(:role => file['role'])
    end

    super
  end

  def validate
    handle_id = self.db[:handle].filter(:transfer_id => self.id).first[:id]
    csv_count = self.db[:transfer_file].filter(:handle_id => handle_id, :role => "CSV").count

    if csv_count > 1
      errors.add(:files, "There can only be one file with a CSV role")
    end

    if self.checklist_metadata_approved == 1 && self.checklist_metadata_received == 0
      errors.add(:checklist, "Cannot check metadata approved until metadata received has been checked")
    end

    if self.checklist_metadata_received == 1 && csv_count == 0
      errors.add(:checklist, "Cannot check metadata received until a CSV file has been attached")
    end
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    MAPDB.open do |mapdb|
      agency_locations =
        mapdb[:agency_location]
          .filter(:agency_id => objs.map(&:agency_id))
          .map {|row| [row[:agency_id], row[:name]]}
          .to_h

      transfer_handles =
        mapdb[:handle]
          .filter(:transfer_id => objs.map(&:id))
          .map {|row| [row[:transfer_id], row[:id]]}
          .to_h

      transfer_files =
        mapdb[:transfer_file]
          .join(:handle,
                Sequel.qualify(:handle, :id) => Sequel.qualify(:transfer_file, :handle_id))
          .filter(Sequel.qualify(:handle, :transfer_id) => objs.map(&:id))
          .order(Sequel.qualify(:transfer_file, :id))
          .all
          .group_by {|row| row[:transfer_id]}

      aspace_agents =
        mapdb[:agency]
          .filter(:id => objs.map(&:agency_id))
          .map {|row| [row[:id], row[:aspace_agency_id]]}
          .to_h

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(aspace_agents.fetch(obj.agency_id))}
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, nil)
        json['handle_id'] = transfer_handles.fetch(obj.id, nil)

        json['handle_id'] = json['handle_id'].to_s if json['handle_id']

        if obj.transfer_proposal_id
          json['transfer_proposal'] = {'ref' => JSONModel(:transfer_proposal).uri_for(obj.transfer_proposal_id)}
        end

        if obj.import_job_uri
          json['import_job'] = {'ref' => obj.import_job_uri}
        end

        json['files'] = transfer_files.fetch(obj.id, []).map {|file|
          {
            'key' => file[:key],
            'filename' => file[:filename],
            'role' => file[:role],
            'mime_type' => file[:mime_type],
          }
        }
      end
    end

    jsons
  end


  def csv
    MAPDB.open do |mapdb|
      mapdb[:transfer_file]
        .join(:handle, Sequel.qualify(:handle, :id) => Sequel.qualify(:transfer_file, :handle_id))
        .filter(Sequel.qualify(:handle, :transfer_id) => self.id)
        .filter(Sequel.qualify(:transfer_file, :role) => 'CSV')
        .join(:file, Sequel.qualify(:file, :key) => Sequel.qualify(:transfer_file, :key))
        .select(Sequel.as(Sequel.qualify(:file, :blob), :data), Sequel.as(Sequel.qualify(:transfer_file, :filename), :filename))
        .first
    end
  end

end
