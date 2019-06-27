class SearchRequest < Sequel::Model
  include ASModel
  corresponds_to JSONModel(:search_request)
  set_model_scope :global

  include MAPModel
  map_table :search_request

  STATUS_CANCELLED_BY_AGENCY = 'CANCELLED_BY_AGENCY'
  STATUS_CANCELLED_BY_QSA = 'CANCELLED_BY_QSA'
  STATUS_SUBMITTED = 'SUBMITTED'
  STATUS_OPEN = 'OPEN'
  STATUS_CLOSED = 'CLOSED'

  def cancel!
    self.status = STATUS_CANCELLED_BY_QSA
    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis
    self.lock_version = self.lock_version + 1

    self.save
  end

  def approve!
    self.status = STATUS_OPEN
    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis
    self.lock_version = self.lock_version + 1

    self.save
  end

  def close!
    self.status = STATUS_CLOSED
    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis
    self.lock_version = self.lock_version + 1

    self.save
  end

  # def generate_quote(quote_type)
  #   json = FileIssueRequest.to_jsonmodel(self)
  # 
  #   type = quote_type.start_with?('p') ? :physical : :digital
  # 
  #   generator = type == :physical ? FileIssuePhysicalQuoteGenerator : FileIssueDigitalQuoteGenerator
  # 
  #   quote = generator.quote_for(json)
  # 
  #   json["#{type}_quote"] = {'ref' => quote.uri}
  # 
  #   cleaned = JSONModel(:file_issue_request).from_hash(json.to_hash)
  # 
  #   self.update_from_json(cleaned)
  # end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    MAPDB.open do |mapdb|
      mapdb[:search_request_item].filter(:search_request_id => self.id).delete
      json['representations'].map {|rep| rep['ref']}.each do |ref|
        parsed_ref = JSONModel.parse_reference(ref)
        record_type = parsed_ref[:type]
        record_id = parsed_ref[:id]

        mapdb[:search_request_item]
          .insert(:search_request_id => self.id,
                  :aspace_record_type => record_type,
                  :aspace_record_id => record_id)
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

      search_request_items =
        mapdb[:search_request_item]
          .filter(Sequel.qualify(:search_request_item, :search_request_id) => objs.map(&:id))
          .all
          .group_by {|row| row[:search_request_id]}

      handles =
        mapdb[:handle]
          .filter(:search_request_id => objs.map(&:id))
          .map {|row| [row[:search_request_id], row[:id]]}
          .to_h

      repo_id_by_item = repo_ids_for_items(search_request_items)

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(aspace_agents.fetch(obj.agency_id))}
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, nil)

        json['handle_id'] = handles.fetch(obj.id, nil)
        json['handle_id'] = json['handle_id'].to_s if json['handle_id']

        representations = search_request_items.fetch(obj.id, [])

        json['requested_representations'] = representations
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

        # if obj.aspace_quote_id
        #   json['quote'] = {'ref' => "/service_quotes/#{obj.aspace_quote_id}"}
        # end

        json['display_string'] = "SR%s" % [obj.id.to_s]
        json['identifier'] = "SR%s" % [obj.id.to_s]
      end
    end

    jsons
  end

  def self.repo_ids_for_items(search_request_items)
    repo_id_by_item_id = {}
    aspace_models = {}

    search_request_items.values.flatten.each do |item|
      aspace_record_type = item[:aspace_record_type]
      aspace_record_id = item[:aspace_record_id]

      aspace_models[aspace_record_type] ||= ASModel.all_models.find {|m| m.my_jsonmodel(true) && (m.my_jsonmodel(true).record_type == aspace_record_type)}

      repo_id_by_item_id[item[:id]] = aspace_models.fetch(aspace_record_type).any_repo[aspace_record_id][:repo_id]
    end

    repo_id_by_item_id
  end

end
