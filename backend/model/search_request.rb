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

    if self.aspace_quote_id
      ServiceQuote[self.aspace_quote_id].withdraw
    end

    self.save
  end

  def approve!
    generate_quote!

    self.refresh
    self.status = STATUS_OPEN
    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis
    self.save
  end

  def close!
    self.status = STATUS_CLOSED
    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis

    if self.aspace_quote_id
      quote = ServiceQuote[self.aspace_quote_id]
      if quote.issued_date.nil?
        ServiceQuote[self.aspace_quote_id].issue
      end
    end

    self.save
  end

  def reopen!
    self.status = STATUS_OPEN
    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis

    self.save
  end

  def generate_quote!
    json = SearchRequest.to_jsonmodel(self)

    generator = SearchRequestQuoteGenerator
    quote = generator.quote_for(json)

    json["quote"] = {'ref' => quote.uri}

    cleaned = JSONModel(:search_request).from_hash(json.to_hash)

    self.update_from_json(cleaned)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    MAPDB.open do |mapdb|
      existing_file_keys = db[:search_request_file].filter(:search_request_id => self.id).map{|row|
        row[:key]
      }

      files_to_add = []
      file_keys_to_keep = []

      json['files'].each do |incoming_file|
        if existing_file_keys.include?(incoming_file.fetch('key'))
          file_keys_to_keep << incoming_file.fetch('key')
        else
          files_to_add << incoming_file
        end
      end

      file_keys_to_remove = existing_file_keys - file_keys_to_keep

      if file_keys_to_remove.length > 0
        db[:search_request_file]
          .filter(:search_request_id => self.id)
          .filter(:key => file_keys_to_remove)
          .delete
      end

      files_to_add.each do |file|
        db[:search_request_file]
          .insert(:search_request_id => self.id,
                  :key => file.fetch('key'),
                  :filename => file.fetch('filename'),
                  :mime_type => file.fetch('mime_type'),
                  :created_by => RequestContext.get(:current_username),
                  :create_time => java.lang.System.currentTimeMillis)
      end

      if json['quote']
        mapdb[:search_request]
          .filter(:id => self.id)
          .update(:aspace_quote_id => JSONModel.parse_reference(json['quote']['ref'])[:id])
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

      search_request_files =
        mapdb[:search_request_file]
          .filter(Sequel.qualify(:search_request_file, :search_request_id) => objs.map(&:id))
          .all
          .group_by {|row| row[:search_request_id]}

      handles =
        mapdb[:handle]
          .filter(:search_request_id => objs.map(&:id))
          .map {|row| [row[:search_request_id], row[:id]]}
          .to_h

      jsons.zip(objs).each do |json, obj|
        json['agency'] = {'ref' => JSONModel(:agent_corporate_entity).uri_for(aspace_agents.fetch(obj.agency_id))}
        json['agency_location_display_string'] = agency_locations.fetch(obj.agency_location_id, nil)

        json['handle_id'] = handles.fetch(obj.id, nil)
        json['handle_id'] = json['handle_id'].to_s if json['handle_id']

        json['files'] = search_request_files.fetch(obj.id, [])
                          .sort_by {|row| row[:create_time]}
                          .map {|file|
          {
            'key' => file[:key],
            'filename' => file[:filename],
            'role' => file[:role],
            'mime_type' => file[:mime_type],
          }
        }

        if obj.aspace_quote_id
          json['quote'] = {'ref' => "/service_quotes/#{obj.aspace_quote_id}"}
        end

        json['display_string'] = "SR%s" % [obj.id.to_s]
        json['identifier'] = "SR%s" % [obj.id.to_s]
      end
    end

    jsons
  end

  def issue_quote!
    ServiceQuote[self.aspace_quote_id].issue

    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis
    self.save
  end

  def withdraw_quote!
    ServiceQuote[self.aspace_quote_id].withdraw

    self.modified_by = RequestContext.get(:current_username)
    self.modified_time = java.lang.System.currentTimeMillis
    self.save
  end
end
