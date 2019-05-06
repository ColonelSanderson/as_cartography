class TransferProposal < Sequel::Model
  include MAPModel
  map_table :transfer_proposal

  include ASModel
  corresponds_to JSONModel(:transfer_proposal)

  set_model_scope :global

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
    elsif key == :last_modified_by
      self.created_by
    else
      super
    end
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
          .join(:transfer_identifier,
                Sequel.qualify(:transfer_identifier, :id) => Sequel.qualify(:transfer_file, :transfer_id))
          .filter(Sequel.qualify(:transfer_identifier, :transfer_proposal_id) => objs.map(&:id))
          .all
          .group_by {|row| row[:transfer_proposal_id]}

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(obj.agency_id)}
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

        json['files'] = proposal_files.fetch(obj.id, []).map {|file|
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
