class IndexerCommon
  @@record_types << :transfer_proposal
  @@record_types << :transfer
  @@record_types << :file_issue_request
  @@record_types << :file_issue
  @@record_types << :search_request
  @@resolved_attributes << 'agency'


  def skip_index_record?(record)
    uri = record['uri']
    reference = JSONModel.parse_reference(uri)
    type = reference && reference[:type]

    (type == 'transfer_proposal' && record['record']['status'] == 'INACTIVE') ||
    (type == 'file_issue_request' && record['record']['draft'])
  end


  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'file_issue'
        doc['file_issue_item_uri_u_sstr'] = ASUtils.wrap(record['record']['requested_representations']).map{|representation| representation['ref']}
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if ['transfer_proposal', 'transfer', 'file_issue_request',
          'file_issue', 'search_request'].include?(doc['primary_type'])

        doc['title'] = record['record']['display_string'] || record['record']['title']

        doc['map_id_u_sort'] = record['record']['identifier'].to_s.rjust(9, '0')
        doc['map_id_u_ssort'] = record['record']['identifier']
        doc['map_agency_id_u_sort'] = record['record']['agency']['_resolved']['qsa_id'].to_s.rjust(9, '0')
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
        # FIRs don't have identifier - sigh
        doc['map_id_u_sort'] = record['record']['title'].to_s.rjust(9, '0')
        doc['map_id_u_ssort'] = record['record']['title']
        doc['file_issue_request_draft_u_sbool'] = record['record']['draft']
        doc['file_issue_request_urgent_u_ssort'] = record['record']['urgent'] ? 'z' : 'a'
        doc['file_issue_request_title_u_ssort'] = record['record']['title']
      end

      if doc['primary_type'] == 'file_issue'
        # FIs don't have identifier - sigh
        doc['map_id_u_sort'] = record['record']['title'].to_s.rjust(9, '0')
        doc['map_id_u_ssort'] = record['record']['title']
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
