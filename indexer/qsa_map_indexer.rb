# Loaded by plugin_init.rb, even though indexer_common.rb will require() this
# file first (prior to PeriodicIndexer being available).
if defined?(PeriodicIndexer)
  class QSAMAPIndexer < PeriodicIndexer

    EXTRA_RESOLVES = [
    ]

    SKIP_RECORD_TYPES = [
      :digital_object,
      :digital_object_component,
      :classification,
      :classification_term,
    ]


    def initialize(backend = nil, state = nil, name = nil, verbose = true, config = {})
      super

      @unpublished_records = java.util.Collections.synchronizedList(java.util.ArrayList.new)
    end


    def resolved_attributes
      super + EXTRA_RESOLVES
    end


    def record_types
      super - SKIP_RECORD_TYPES
    end


    def configure_doc_rules
      super

      record_has_children('resource')
      record_has_children('archival_object')

      # FIXME: Working around the fact that series system plugin hasn't loaded here.
      add_document_prepare_hook do |doc, record|
        if record['record'].has_key?('responsible_agency')
          doc['responsible_agency_u_sstr'] = record['record']['responsible_agency']['ref']
        end

        if record['record'].has_key?('other_responsible_agencies')
          doc['other_responsible_agencies_u_sstr'] = record['record']['other_responsible_agencies'].map{|r| r['ref']}
        end
      end

      add_document_prepare_hook {|doc, record|
        if doc['primary_type'] == 'agent_corporate_entity'
          doc['id'] = "agent_corporate_entity:#{doc['id'].split('/')[-1]}"
          doc['aspace_id'] = doc['id'].split('/')[-1]
          doc['display_string'] = doc['title']
          doc['keywords'] = doc['title']
          doc['record_type'] = 'agent_corporate_entity'
        end
      }

      #     {
      #       "id" => "agent_corporate_entity:#{row[:id]}",
      #       "aspace_id" => row[:id].to_s,
      #       "display_string" => row[:sort_name],
      #       "keywords" => row[:sort_name],
      #       "record_type" => "agent_corporate_entity",
      #     }


    end


    def skip_index_record?(record)
      published = record['record']['publish']

      stage_unpublished_for_deletion(record['record']['uri']) unless published

      !published
      false
    end


    def skip_index_doc?(doc)
      published = doc['publish']

      stage_unpublished_for_deletion(doc['id']) unless published

      !published
      false
    end


    def index_round_complete(repository)
      # Delete any unpublished records and decendents
      #    delete_records(@unpublished_records, :parent_id_field => 'parent_id')
      @unpublished_records.clear()
    end


    def stage_unpublished_for_deletion(doc_id)
      @unpublished_records.add(doc_id)
    end
  end
end
