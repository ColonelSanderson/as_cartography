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
            'ref' => JSONModel(item[:aspace_record_type].intern)
                       .uri_for(item[:aspace_record_id],
                                :repo_id => repo_id_by_item.fetch(item[:id])),
            'request_type' => item[:request_type],
            'record_details' => item[:record_details],
          }
        }

        json['file_issue_request'] = {'ref' => JSONModel(:file_issue_request).uri_for(obj.file_issue_request_id)}
      end
    end

    jsons
  end

end
