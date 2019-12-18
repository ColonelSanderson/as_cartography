class IndexerCommon
  @@record_types << :transfer_proposal
  @@record_types << :transfer
  @@record_types << :file_issue_request
  @@record_types << :file_issue
  @@record_types << :search_request
  @@record_types << :agency_reading_room_request
  @@resolved_attributes << 'agency'
  @@resolved_attributes << 'requesting_agency'


  def skip_index_record?(record)
    uri = record['uri']
    reference = JSONModel.parse_reference(uri)
    type = reference && reference[:type]

    (type == 'transfer_proposal' && record['record']['status'] == 'INACTIVE') ||
    (type == 'file_issue_request' && record['record']['draft'])
  end


  add_indexer_initialize_hook do |indexer|
    QSAId.mode(:indexer)
    require_relative '../common/qsa_id_registrations'

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'agency_reading_room_request'
        doc['types'] = ['reading_room_request', 'agency_reading_room_request']

        doc['rrr_date_required_u_ssortdate'] = "%sT00:00:00Z" % [Time.at(record['record']['date_required'] / 1000).to_date.iso8601]
        doc['rrr_time_required_u_ssort'] = record['record']['time_required']

        doc['rrr_date_created_u_ssortdate'] = record['record']['create_time']
        doc['rrr_status_u_ssort'] = record['record']['status']

        item = record['record']['requested_item']['_resolved']

        doc['rrr_requested_item_qsa_id_u_ssort'] = item['qsa_id_prefixed']
        doc['rrr_requested_item_qsa_id_u_sort'] = IndexerCommon.sort_value_for_qsa_id(item['qsa_id_prefixed'])
        doc['rrr_requested_item_availability_u_ssort'] = item['calculated_availability']
        requested_by = "%s - %s" % [record['record'].dig('requesting_agency','_resolved','display_string'), record['record'].dig('requesting_agency','location_name')]
        doc['rrr_requesting_user_u_ssort'] = requested_by
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'file_issue'
        doc['file_issue_item_uri_u_sstr'] = ASUtils.wrap(record['record']['requested_representations']).map{|representation| representation['ref']}
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if ['transfer_proposal', 'transfer', 'file_issue_request',
          'file_issue', 'search_request'].include?(doc['primary_type'])

        doc['title'] = record['record']['display_string'] || record['record']['title']

        if doc['primary_type'] == 'file_issue'
          doc['qsa_id_u_sort'] = record['record']['qsa_id'].to_s.rjust(9, '0')
        else
          doc['qsa_id_u_sort'] = IndexerCommon.sort_value_for_qsa_id(record['record']['qsa_id_prefixed'])
        end
        doc['qsa_id_u_ssort'] = record['record']['qsa_id_prefixed']
        doc['map_agency_id_u_sort'] = record['record']['agency']['_resolved']['qsa_id'].to_s.gsub(/\D+/,'').rjust(9, '0')
        doc['map_agency_id_u_ssort'] = record['record']['agency']['_resolved']['qsa_id']
        doc['map_agency_name_u_ssort'] = record['record']['agency']['_resolved']['display_name']['sort_name']
      end

      if doc['primary_type'] == 'transfer_proposal'
        doc['transfer_status_u_sstr'] = record['record']['status']
        doc['transfer_proposal_title_u_ssort'] = record['record']['title']
        doc['transfer_proposal_status_u_ssort'] = record['record']['status']
      end

      if doc['primary_type'] == 'transfer'
        doc['transfer_title_u_ssort'] = record['record']['title']
        doc['transfer_status_u_ssort'] = record['record']['status']
      end

      if doc['primary_type'] == 'file_issue_request'
        doc['file_issue_request_draft_u_sbool'] = record['record']['draft']
        doc['file_issue_request_urgent_u_ssort'] = record['record']['urgent'] ? 'z' : 'a'
        doc['file_issue_request_title_u_ssort'] = record['record']['title']
      end

      if doc['primary_type'] == 'file_issue'
        doc['file_issue_urgent_u_ssort'] = record['record']['urgent'] ? 'z' : 'a'
        doc['file_issue_title_u_ssort'] = record['record']['title']
        doc['file_issue_status_u_ssort'] = record['record']['status']
      end

      if doc['primary_type'] == 'search_request'
        doc['search_request_id_u_ssort'] = record['record']['display_string']
        doc['search_request_status_u_ssort'] = record['record']['status']
      end
    }
  end
end
