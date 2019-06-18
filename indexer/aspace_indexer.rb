class IndexerCommon
  @@record_types << :transfer_proposal
  @@record_types << :transfer
  @@record_types << :file_issue_request
  @@record_types << :file_issue
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
    }

  end
end
