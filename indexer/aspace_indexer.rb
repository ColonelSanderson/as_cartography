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
      if doc['primary_type'] == 'transfer'
        doc['title'] = record['record']['display_string']
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'transfer_proposal'
        doc['title'] = record['record']['display_string']
        doc['transfer_status_u_sstr'] = record['record']['status']
        doc['transfer_proposal_title_u_ssort'] = record['record']['title']
        doc['transfer_proposal_id_u_ssort'] = record['record']['identifier']
        doc['transfer_proposal_status_u_ssort'] = record['record']['status']
        doc['transfer_proposal_agency_id_u_ssort'] = record['record']['agency']['_resolved']['qsa_id']
        doc['transfer_proposal_agency_name_u_ssort'] = record['record']['agency']['_resolved']['display_name']['sort_name']
      end

      if doc['primary_type'] == 'transfer'
        doc['title'] = record['record']['display_string']
        doc['transfer_title_u_ssort'] = record['record']['title']
        doc['transfer_id_u_ssort'] = record['record']['identifier']
        doc['transfer_status_u_ssort'] = record['record']['status']
        doc['transfer_agency_id_u_ssort'] = record['record']['agency']['_resolved']['qsa_id']
        doc['transfer_agency_name_u_ssort'] = record['record']['agency']['_resolved']['display_name']['sort_name']
      end

      if doc['primary_type'] == 'file_issue_request'
        doc['file_issue_request_draft_u_sbool'] = record['record']['draft']
        doc['file_issue_request_urgent_u_ssort'] = record['record']['urgent'] ? 'z' : 'a'
        doc['file_issue_request_title_u_ssort'] = record['record']['title']
        doc['file_issue_request_agency_id_u_ssort'] = record['record']['agency']['_resolved']['qsa_id']
        doc['file_issue_request_agency_name_u_ssort'] = record['record']['agency']['_resolved']['display_name']['sort_name']
      end

      if doc['primary_type'] == 'file_issue'
        doc['file_issue_urgent_u_ssort'] = record['record']['urgent'] ? 'z' : 'a'
        doc['file_issue_title_u_ssort'] = record['record']['title']
        doc['file_issue_agency_id_u_ssort'] = record['record']['agency']['_resolved']['qsa_id']
        doc['file_issue_status_u_ssort'] = record['record']['status']
        doc['file_issue_agency_name_u_ssort'] = record['record']['agency']['_resolved']['display_name']['sort_name']
      end

      if doc['primary_type'] == 'search_request'
        doc['title'] = record['record']['display_string']
        doc['search_request_id_u_ssort'] = record['record']['display_string']
        doc['search_request_agency_id_u_ssort'] = record['record']['agency']['_resolved']['qsa_id']
        doc['search_request_status_u_ssort'] = record['record']['status']
        doc['search_request_agency_name_u_ssort'] = record['record']['agency']['_resolved']['display_name']['sort_name']
      end
    }
  end
end
