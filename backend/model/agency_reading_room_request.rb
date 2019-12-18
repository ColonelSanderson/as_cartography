class AgencyReadingRoomRequest < Sequel::Model
  include ASModel
  corresponds_to JSONModel(:agency_reading_room_request)
  set_model_scope :global

  include MAPModel
  map_table :reading_room_request

  include ItemUses

  STATUS_AWAITING_AGENCY_APPROVAL = 'AWAITING_AGENCY_APPROVAL'
  STATUS_APPROVED_BY_AGENCY = 'APPROVED_BY_AGENCY'
  STATUS_REJECTED_BY_AGENCY = 'REJECTED_BY_AGENCY'
  STATUS_PENDING = 'PENDING'
  STATUS_BEING_RETRIEVED = 'BEING_RETRIEVED'
  STATUS_DELIVERED_TO_READING_ROOM = 'DELIVERED_TO_READING_ROOM'
  STATUS_DELIVERED_TO_ARCHIVIST = 'DELIVERED_TO_ARCHIVIST'
  STATUS_DELIVERED_TO_CONSERVATION = 'DELIVERED_TO_CONSERVATION'
  STATUS_COMPLETE = 'COMPLETE'
  STATUS_CANCELLED_BY_QSA = 'CANCELLED_BY_QSA'
  STATUS_CANCELLED_BY_RESEARCHER = 'CANCELLED_BY_RESEARCHER'
  
  VALID_STATUS = [
    STATUS_AWAITING_AGENCY_APPROVAL,
    STATUS_APPROVED_BY_AGENCY,
    STATUS_REJECTED_BY_AGENCY,
    STATUS_PENDING,
    STATUS_BEING_RETRIEVED,
    STATUS_DELIVERED_TO_READING_ROOM,
    STATUS_DELIVERED_TO_ARCHIVIST,
    STATUS_DELIVERED_TO_CONSERVATION,
    STATUS_COMPLETE,
    STATUS_CANCELLED_BY_QSA,
    STATUS_CANCELLED_BY_RESEARCHER,
  ]

  READING_ROOM_LOCATION_ENUM_VALUE = 'PSR'
  HOME_LOCATION_ENUM_VALUE = 'HOME'
  CONSERVATION_LOCATION_ENUM_VALUE = 'CONS'
  TODESK_LOCATION_ENUM_VALUE = 'TODESK'

  STATUSES_TRIGGERING_MOVEMENTS = {
    STATUS_DELIVERED_TO_READING_ROOM => READING_ROOM_LOCATION_ENUM_VALUE,
    STATUS_COMPLETE => HOME_LOCATION_ENUM_VALUE,
    STATUS_DELIVERED_TO_CONSERVATION => CONSERVATION_LOCATION_ENUM_VALUE,
    STATUS_DELIVERED_TO_ARCHIVIST => TODESK_LOCATION_ENUM_VALUE,
  }


  def update_from_json(json, opts = {}, apply_nested_records = true)
    # opts['modified_time'] = java.lang.System.currentTimeMillis
    # opts['modified_by'] = RequestContext.get(:current_username)

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
        mapdb[:agency_location].filter(:agency_id => objs.map(&:agency_id)).map {|row| [row[:id], row[:name]]}.to_h

      handles =
        mapdb[:handle]
          .filter(:reading_room_request_id => objs.map(&:id))
          .map {|row| [row[:reading_room_request_id], row[:id]]}
          .to_h

      jsons.zip(objs).each do |json, obj|
        json['title'] = "Reading Room Request #{obj.id}"
        json['requested_item'] = {'ref' => json['item_uri']}
        json['requesting_agency'] = {
          'ref' => JSONModel(:agent_corporate_entity).uri_for(aspace_agents.fetch(obj.agency_id)),
          'location_name' => agency_locations.fetch(obj.agency_location_id),
        }
        json['handle_id'] = handles.fetch(obj.id)
      end
    end

    jsons
  end

  def set_status(status)
    MAPDB.open do |db|
      json = self.class.to_jsonmodel(self)

      if VALID_STATUS.include?(status)
        parsed_item_uri = JSONModel.parse_reference(self.item_uri)

        if STATUSES_TRIGGERING_MOVEMENTS.keys.include?(status) && parsed_item_uri[:type] == 'physical_representation'
          repo_uri = parsed_item_uri[:repository]
          repo_id = JSONModel.parse_reference(repo_uri)[:id]

          RequestContext.open(:repo_id => repo_id) do
            requested_item = PhysicalRepresentation.get_or_die(parsed_item_uri[:id])
            requested_item.move(:context => self.uri,
                                :location => STATUSES_TRIGGERING_MOVEMENTS[status])
          end
        end

        json.status = status
        cleaned = JSONModel(:agency_reading_room_request).from_hash(json.to_hash)
        self.update_from_json(cleaned)
      end
    end
  end

  def self.get_status_map(uris)
    ids = uris.map{|uri| JSONModel(:agency_reading_room_request).id_for(uri)}
    MAPDB.open do |db|
      db[:reading_room_request]
        .filter(:id => ids)
        .select(:id, :status)
        .map {|row| [JSONModel(:agency_reading_room_request).uri_for(row[:id]), row[:status]]}.to_h
    end
  end

  def self.resolve_requested_items(record_uris)
    result = {}

    record_uris
      .map{|uri| JSONModel.parse_reference(uri) }
      .group_by{|parsed| parsed[:type]}
      .each do |jsonmodel_type, parsed_uris|
      ids = parsed_uris.map{|parsed| parsed[:id]}

      model = jsonmodel_type == 'physical_representation' ? PhysicalRepresentation : DigitalRepresentation

      objs = model
               .any_repo
               .filter(:id => ids)
               .all

      objs.group_by{|obj| obj.repo_id}.each do |repo_id, objs|
        RequestContext.open(:repo_id => repo_id) do
          model.sequel_to_jsonmodel(objs).each do |json|
            result[json.uri] = json
          end
        end
      end
    end

    result
  end

  def self.prepare_search_results(search_results)
    uri_to_json = search_results['results']
                    .select{|result| result['primary_type'] == 'agency_reading_room_request'}
                    .map{|result| [result.fetch('uri'), ASUtils.json_parse(result.fetch('json'))]}.to_h

    status_map = get_status_map(uri_to_json.keys)

    requested_item_uris = uri_to_json.values.map{|json| json.fetch('item_uri')}
    resolved_items = resolve_requested_items(requested_item_uris)

    search_results['results'].each do |result|
      next unless result['primary_type'] == 'agency_reading_room_request'
      uri = result.fetch('uri')

      json = uri_to_json.fetch(uri)
      json['status'] = status_map.fetch(uri)
      json['requested_item']['_resolved'] = resolved_items.fetch(json.fetch('item_uri'))
      result['json'] = json.to_json
    end

    search_results
  end

  def self.to_item_uses(json)
    return [] unless json['date_required']

    # only supported on physical representation
    return [] unless JSONModel.parse_reference(json['item_uri'])[:type] == 'physical_representation'

    reading_room_request_id = JSONModel.parse_reference(json['uri'])[:id]

    aspace_agency_id = nil
    location_name = 'Unknown Location'

    MAPDB.open do |mapdb|
      request = mapdb[:reading_room_request][:id => reading_room_request_id]
      agency_id = request[:agency_id]
      location_id = request[:agency_location_id]
      aspace_agency_id = mapdb[:agency][:id => agency_id][:aspace_agency_id]
      location_name = mapdb[:agency_location][:id => location_id][:name]
    end

    agency_label = if aspace_agency_id
                      agency = AgentCorporateEntity.to_jsonmodel(aspace_agency_id)
                      agency.title
                   else
                      'Unknown Agency'
                   end

    used_by = "%s - %s" % [agency_label, location_name]

    qsa_id = QSAId.prefixed_id_for(AgencyReadingRoomRequest,
                                   reading_room_request_id)

    start_date = Time.at(json['date_required']/1000).strftime('%Y-%m-%d')

    JSONModel(:item_use).from_hash({
      'physical_representation' => {'ref' => json['item_uri']},
      'item_use_type' => 'agency_reading_room_request',
      'use_identifier' => qsa_id,
      'status' => json['status'],
      'used_by' => used_by,
      'start_date' => start_date
    })
  end
end
