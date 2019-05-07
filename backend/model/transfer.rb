class Transfer < Sequel::Model

  STATUS_APPROVED = 'APPROVED'

  CHECKLIST_APPROVED = 'TRANSFER_PROPOSAL_APPROVED'
  TRANSFER_PROCESS_INITIATED = 'TRANSFER_PROCESS_INITIATED'

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
                          :checklist_status => CHECKLIST_APPROVED,
                          :transfer_proposal_id => proposal_id)

    self.db[:handle].insert(:transfer_id => created.id)

    self.db[:transfer_proposal]
      .filter(:id => proposal_id)
      .update(:status => STATUS_APPROVED)

    created
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
          .all
          .group_by {|row| row[:transfer_id]}

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(obj.agency_id)}
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, nil)
        json['handle_id'] = transfer_handles.fetch(obj.id, nil)

        json['handle_id'] = json['handle_id'].to_s if json['handle_id']

        if obj.transfer_proposal_id
          json['transfer_proposal'] = {'ref' => JSONModel(:transfer_proposal).uri_for(obj.transfer_proposal_id)}
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




end
