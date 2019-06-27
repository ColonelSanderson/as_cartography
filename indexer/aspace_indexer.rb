class IndexerCommon
  @@record_types << :transfer_proposal
  @@record_types << :transfer
  @@record_types << :file_issue_request
  @@record_types << :file_issue
  @@record_types << :search_request
  @@resolved_attributes << 'agency'

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'file_issue'
        doc['file_issue_item_uri_u_sstr'] = ASUtils.wrap(record['record']['requested_representations']).map{|representation| representation['ref']}
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'transfer'
        doc['title'] = record['record']['display_string']
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'transfer_proposal'
        doc['title'] = record['record']['display_string']
        doc['transfer_status_u_sstr'] = record['record']['status']
      end

      if doc['primary_type'] == 'file_issue_request'
        doc['file_issue_request_draft_u_sbool'] = record['record']['draft']
        doc['file_issue_request_urgent_u_ssort'] = record['record']['urgent'] ? 'z' : 'a'
        doc['file_issue_request_title_u_ssort'] = record['record']['title']
        doc['file_issue_request_agency_id_u_ssort'] = record['record']['agency']['_resolved']['qsa_id']
        doc['file_issue_request_agency_name_u_ssort'] = record['record']['agency']['_resolved']['display_name']['sort_name']
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'search_request'
        doc['title'] = record['record']['display_string']
        doc['search_request_draft_u_sbool'] = record['record']['draft']
        doc['search_request_status_u_sstr'] = record['record']['status']
      end
    }

  end
end
