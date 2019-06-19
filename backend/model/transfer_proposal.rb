class TransferProposal < Sequel::Model
  include ASModel
  corresponds_to JSONModel(:transfer_proposal)
  set_model_scope :global

  include MAPModel
  map_table :transfer_proposal

  CANCELLED_BY_QSA_STATUS = 'CANCELLED_BY_QSA'

  def cancel!
    self.status = CANCELLED_BY_QSA_STATUS
    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis
    self.save
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    MAPDB.open do |mapdb|
      agency_locations =
        mapdb[:agency_location].filter(:agency_id => objs.map(&:agency_id)).map {|row| [row[:agency_id], row[:name]]}.to_h

      proposal_series =
        mapdb[:transfer_proposal_series]
          .filter(:transfer_proposal_id => objs.map(&:id))
          .all
          .group_by {|row| row[:transfer_proposal_id]}

      proposal_files =
        mapdb[:transfer_file]
          .join(:handle,
                Sequel.qualify(:handle, :id) => Sequel.qualify(:transfer_file, :handle_id))
          .filter(Sequel.qualify(:handle, :transfer_proposal_id) => objs.map(&:id))
          .all
          .group_by {|row| row[:transfer_proposal_id]}

      transfer_ids =
        mapdb[:transfer]
          .filter(:transfer_proposal_id => objs.map(&:id))
          .all
          .group_by {|row| row[:transfer_proposal_id]}

      aspace_agents =
        mapdb[:agency]
          .filter(:id => objs.map(&:agency_id))
          .map {|row| [row[:id], row[:aspace_agency_id]]}
          .to_h

      transfer_handles =
        mapdb[:handle]
          .filter(:transfer_proposal_id => objs.map(&:id))
          .map {|row| [row[:transfer_proposal_id], row[:id]]}
          .to_h

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(aspace_agents.fetch(obj.agency_id))}
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, nil)

        json['series'] = proposal_series.fetch(obj.id, []).map {|series_row|
          {
            'title' => series_row[:series_title],
            'disposal_class' => series_row[:disposal_class],
            'date_range' => series_row[:date_range],
            'accrual_details' => series_row[:accrual_details],
            'creating_agency' => series_row[:creating_agency],
            'mandate' => series_row[:mandate],
            'function' => series_row[:function],
            'system_of_arrangement' => series_row[:system_of_arrangement],
            'composition' => ['digital', 'hybrid', 'physical'].select {|composition|
              series_row[:"composition_#{composition}"] == 1
            }
          }
        }

        json['handle_id'] = transfer_handles.fetch(obj.id, nil)
        json['handle_id'] = json['handle_id'].to_s if json['handle_id']


        if transfer_ids.fetch(obj.id, nil)
          json['transfer'] = {'ref' => JSONModel(:transfer).uri_for(transfer_ids.fetch(obj.id)[0][:id])}
        end

        json['files'] = proposal_files.fetch(obj.id, []).map {|file|
          {
            'key' => file[:key],
            'filename' => file[:filename],
            'role' => file[:role],
            'mime_type' => file[:mime_type],
          }
        }

        json['identifier'] = "P%s" % [obj.id.to_s]
        json['display_string'] = "%s: %s" % [json['identifier'], json['title']]
      end
    end

    jsons
  end


end
