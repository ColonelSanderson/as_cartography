load File.join(File.dirname(__FILE__), '..', '..', '..', 'indexer', 'app', 'lib', 'periodic_indexer.rb')


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

    add_document_prepare_hook {|doc, record|
      puts "DOING!"
    }

  end


  def skip_index_record?(record)
    published = record['record']['publish']

    stage_unpublished_for_deletion(record['record']['uri']) unless published

    !published
  end


  def skip_index_doc?(doc)
    published = doc['publish']

    stage_unpublished_for_deletion(doc['id']) unless published

    !published
  end


  def index_round_complete(repository)

    # Delete any unpublished records and decendents
    delete_records(@unpublished_records, :parent_id_field => 'parent_id')
    @unpublished_records.clear()

    checkpoints.each do |repository, type, start|
      @state.set_last_mtime(repository.id, type, start)
    end

  end

  def stage_unpublished_for_deletion(doc_id)
    @unpublished_records.add(doc_id)
  end
end
