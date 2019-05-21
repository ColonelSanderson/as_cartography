class FileIssueRequest < Sequel::Model
  include ASModel
  corresponds_to JSONModel(:file_issue_request)
  set_model_scope :global

  include MAPModel
  map_table :file_issue_request

  CANCELLED_BY_QSA_STATUS = 'CANCELLED_BY_QSA'

  def cancel!(cancel_target)
    case cancel_target
        when 'physical', 'both'
          self.physical_request_status = CANCELLED_BY_QSA_STATUS
        when 'digital', 'both'
          self.digital_request_status = CANCELLED_BY_QSA_STATUS
    end

    self.save
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # Requested representations can be re-linked.  Apply those updates.
    MAPDB.open do |mapdb|
      new_urls = json['requested_representations'].map {|rep| rep['ref']}

      existing_items = mapdb[:file_issue_request_item].filter(:file_issue_request_id => self.id).order(:id).map {|row|
        row[:id]
      }

      if new_urls.length != existing_items.length
        raise "Unexpected mismatch between number of representations on update vs storage"
      end

      new_urls.zip(existing_items).each do |new_ref, request_item_id|
        parsed_ref = JSONModel.parse_reference(new_ref)

        record_type = parsed_ref[:type]
        record_id = parsed_ref[:id]

        mapdb[:file_issue_request_item]
          .filter(:id => request_item_id)
          .update(:aspace_record_type => record_type,
                  :aspace_record_id => record_id)
      end

      # Update ids for physical and digital quotes
      ['physical_quote', 'digital_quote'].each do |quote|
        if json[quote]
          mapdb[:file_issue_request]
            .filter(:id => self.id)
            .update(:"aspace_#{quote}_id" => JSONModel.parse_reference(json[quote]['ref'])[:id])
        end
      end

      super
    end
  end


  # We need to build URIs for representations, but the MAP doesn't have any
  # notion of an active repository.  So, we work out the repository that each
  # referenced representation belongs to and work backwards from that.
  def self.repo_ids_for_items(file_issue_request_items)
    repo_id_by_item_id = {}
    aspace_models = {}

    file_issue_request_items.values.flatten.each do |item|
      aspace_record_type = item[:aspace_record_type]
      aspace_record_id = item[:aspace_record_id]

      aspace_models[aspace_record_type] ||= ASModel.all_models.find {|m| m.my_jsonmodel(true) && (m.my_jsonmodel(true).record_type == aspace_record_type)}

      repo_id_by_item_id[item[:id]] = aspace_models.fetch(aspace_record_type).any_repo[aspace_record_id][:repo_id]
    end

    repo_id_by_item_id
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

      file_issue_request_items =
        mapdb[:file_issue_request_item]
          .filter(Sequel.qualify(:file_issue_request_item, :file_issue_request_id) => objs.map(&:id))
          .all
          .group_by {|row| row[:file_issue_request_id]}

      handles =
        mapdb[:handle]
          .filter(:file_issue_request_id => objs.map(&:id))
          .map {|row| [row[:file_issue_request_id], row[:id]]}
          .to_h

      repo_id_by_item = repo_ids_for_items(file_issue_request_items)

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(aspace_agents.fetch(obj.agency_id))}
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, nil)

        json['handle_id'] = handles.fetch(obj.id, nil)
        json['handle_id'] = json['handle_id'].to_s if json['handle_id']

        requested_representations = file_issue_request_items.fetch(obj.id, [])

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

        if obj.aspace_physical_quote_id
          json['physical_quote'] = {'ref' => "/service_quotes/#{obj.aspace_physical_quote_id}"}
        end

        if obj.aspace_digital_quote_id
          json['digital_quote'] = {'ref' => "/service_quotes/#{obj.aspace_digital_quote_id}"}
        end

        json['title'] = "%s" % [Time.at(obj.create_time).to_s]
      end
    end

    jsons
  end

end
