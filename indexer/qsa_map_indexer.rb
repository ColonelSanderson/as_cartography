# Loaded by plugin_init.rb, even though indexer_common.rb will require() this
# file first (prior to PeriodicIndexer being available).
if defined?(PeriodicIndexer)
  class QSAMAPIndexer < PeriodicIndexer

    # Current unused
    EXTRA_RESOLVES = []

    SKIP_RECORD_TYPES = [
      :digital_object,
      :digital_object_component,
      :classification,
      :classification_term,
    ]


    def resolved_attributes
      super + EXTRA_RESOLVES
    end


    def record_types
      super - SKIP_RECORD_TYPES
    end


    def configure_doc_rules
      super

      add_document_prepare_hook {|doc, record|
        if doc['primary_type'] == 'agent_corporate_entity'
          doc['id'] = "agent_corporate_entity:#{doc['id'].split('/')[-1]}"
          doc['aspace_id'] = doc['id'].split('/')[-1]
          doc['display_string'] = doc['title']
          doc['keywords'] = doc['title']
          doc['record_type'] = 'agent_corporate_entity'
        end

        add_document_prepare_hook do |doc, record|
          if record['record'].has_key?('responsible_agency')
            doc['responsible_agency_u_sstr'] = record['record']['responsible_agency']['ref']
          end

          if record['record'].has_key?('recent_responsible_agencies')
            doc['recent_responsible_agencies_u_sstr'] = record['record']['recent_responsible_agencies'].map{|r| r['ref']}
          end

          if record['record'].has_key?('other_responsible_agencies')
            doc['other_responsible_agencies_u_sstr'] = record['record']['other_responsible_agencies'].map{|r| r['ref']}
          end
        end
      }
    end
  end
end
