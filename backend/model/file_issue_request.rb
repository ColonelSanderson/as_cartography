class FileIssueRequest < Sequel::Model
  include ASModel
  corresponds_to JSONModel(:file_issue_request)
  set_model_scope :global

  include MAPModel
  map_table :file_issue_request

  include FileIssueHelpers

  CANCELLED_BY_QSA_STATUS = 'CANCELLED_BY_QSA'
  FILE_ISSUE_CREATED_STATUS = 'FILE_ISSUE_CREATED'
  INITIATED_STATUS = 'INITIATED'

  def cancel!(cancel_target)
    if ['physical', 'both'].include?(cancel_target)
      self.physical_request_status = CANCELLED_BY_QSA_STATUS
    end
    if ['digital', 'both'].include?(cancel_target)
      self.digital_request_status = CANCELLED_BY_QSA_STATUS
    end

    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis

    self.save
  end

  def approve!(approve_target)
    if ['physical', 'both'].include?(approve_target)
      spawn_file_issue('PHYSICAL')
      self.physical_request_status = FILE_ISSUE_CREATED_STATUS
    end

    if ['digital', 'both'].include?(approve_target)
      spawn_file_issue('DIGITAL')
      self.digital_request_status = FILE_ISSUE_CREATED_STATUS
    end

    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis

    self.save
  end

  def spawn_file_issue(file_issue_type)
    spawn_values = self.values.merge(
      :file_issue_request_id => self.id,
      :issue_type => file_issue_type,
      :status => INITIATED_STATUS,
    )

    # Exclude protected values
    [:lock_version, :created_by, :create_time, :modified_by, :modified_time,
     :system_mtime, :id].each do |prop|
      spawn_values.delete(prop)
    end

    file_issue = FileIssue.create(spawn_values)

    self.db[:handle].insert(:file_issue_id => file_issue.id)

    # Copy each of the requested items into our file issue
    MAPDB.open do |mapdb|
      db[:file_issue_request_item]
        .filter(:file_issue_request_id => self.id,
                :request_type => file_issue_type)
        .each do |request_item|
        db[:file_issue_item].insert(
          :file_issue_id => file_issue.id,
          :aspace_record_type => request_item[:aspace_record_type],
          :aspace_record_id => request_item[:aspace_record_id],
          :record_details => request_item[:record_details],
        )
      end
    end
  end

  def generate_quote(quote_type)
    json = FileIssueRequest.to_jsonmodel(self)

    type = quote_type.start_with?('p') ? :physical : :digital

    generator = type == :physical ? FileIssuePhysicalQuoteGenerator : FileIssueDigitalQuoteGenerator

    quote = generator.quote_for(json)

    json["#{type}_quote"] = {'ref' => quote.uri}

    cleaned = JSONModel(:file_issue_request).from_hash(json.to_hash)

    self.update_from_json(cleaned)
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


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    MAPDB.open do |mapdb|
      aspace_agents =
        mapdb[:agency]
          .filter(:id => objs.map(&:agency_id))
          .map {|row| [row[:id], row[:aspace_agency_id]]}
          .to_h

      agency_locations =
        mapdb[:agency_location].filter(:agency_id => objs.map(&:agency_id)).map {|row| [row[:id], row[:name]]}.to_h

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

      file_issues =
        mapdb[:file_issue]
          .filter(:file_issue_request_id => objs.map(&:id))
          .all
          .group_by {|row| row[:file_issue_request_id]}

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

        file_issues.fetch(obj.id, []).each do |file_issue|
          issue_type = file_issue[:issue_type].downcase
          json["file_issue_#{issue_type}"] = {'ref' => JSONModel(:file_issue).uri_for(file_issue[:id])}
        end

        json['title'] = QSAId.prefixed_id_for(FileIssueRequest, obj.id)
      end
    end

    jsons
  end

end
