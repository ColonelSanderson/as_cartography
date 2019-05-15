require 'zlib'
require_relative 'indexer_state'

# Previously we were using a regular ArchivesSpace indexer to read
# records from the ArchivesSpace backend and POST them to MAP's Solr
# instance.  This won't work in production because we'll have N
# ArchivesSpace instances and M MAP instances and we don't want every
# ArchivesSpace instance to have to know about every MAP instance's
# Solr.
#
# This indexer is much like the ArchivesSpace periodic indexer (in that
# it wakes up periodically, figures out what's new, pulls out the
# records and maps them), but it writes to a table in the MAP database
# instead of directly to Solr.  That way, MAP instances can consume a
# stream of record updates from this new table to bring themselves
# up-to-date.
#
# Mapping records to Solr documents is done here, rather than on the MAP
# side, because it seems likely that it'll be easier to schedule a
# restart of ArchivesSpace due to changed indexing rules than to take
# down the MAP.  Also, since the Solr documents are quite a bit smaller
# than the JSONModel objects they're derived from, it saves on storage.

class IndexFeedThread

  INDEX_BATCH_SIZE = 25

  MTIME_WINDOW_SECONDS = 30

  RECORD_TYPES = [
    Resource,
    ArchivalObject,
    AgentCorporateEntity,
  ]


  def initialize
    @state = IndexState.new("indexer_plugin_qsauatmap_state")
  end

  def call
    loop do
      begin
        run_index_round_with_backoff
      rescue
        Log.error("Error from index_feed_thread: #{$!}")
        Log.exception($!)
      end

      sleep AppConfig[:map_index_feed_interval_seconds]
    end
  end

  def run_index_round_with_backoff
    begin
      # Improve our chances of indexers across multiple machines not running in
      # lockstep.  Not that it really matters, but just saves wasted effort.
      sleep (rand * 5)
      run_index_round
    rescue Sequel::DatabaseError => e
      if (e.wrapped_exception && ( e.wrapped_exception.cause or e.wrapped_exception).getSQLState() =~ /^23/)
        # Constraint violations (23*) are expected if we insert a record into
        # the feed at the same time as another node does.  We'll let these roll
        # back the transaction and try again later.
      else
        # Something more serious went wrong?
        raise e
      end
    end
  end

  def run_index_round
    # Set the isolation level to READ_COMMITTED so we observe the effects of
    # other concurrent indexer threads (on other machines)
    MAPDB.open(true, :isolation_level => :committed) do |mapdb|
      Repository.each do |repo|
        RECORD_TYPES.each do |record_type|
          now = Time.now
          record_type_name = record_type.name.downcase

          last_index_epoch = [(@state.get_last_mtime(repo.id, record_type_name) - MTIME_WINDOW_SECONDS), 0].max
          last_index_time = Time.at(last_index_epoch)

          if last_index_epoch == 0
            # This is a reindex.  We'll do what you'd expect and clear all
            # existing records.  New record will get assigned higher
            # auto-incrementing IDs and the MAP will see those as new records
            # and index them again.
            mapdb[:index_feed].filter(:repo_id => repo.id, :record_type => record_type.my_jsonmodel.record_type).delete
          end

          did_something = false

          RequestContext.open(:repo_id => repo.id) do
            record_type
              .this_repo
              .filter { system_mtime > last_index_time }
              .select(:id, :lock_version).each_slice(INDEX_BATCH_SIZE) do |id_set|

              # Other nodes might have got in first on some of these records.
              # And, actually, because we use MTIME_WINDOW_SECONDS to overlap
              # our mtime checks, we might have indexed some of them on a
              # previous run too.  In any case, skip over them.
              uri_set = id_set.map {|row| record_type.uri_for(record_type.my_jsonmodel.record_type, row.id)}

              already_indexed = mapdb[:index_feed].filter(:record_uri => uri_set)
                                  .select(:record_id, :lock_version)
                                  .map {|row| [row[:record_id], row[:lock_version]]}
                                  .to_h

              id_set.reject! {|row| already_indexed[row[:id]] && already_indexed[row[:id]] >= row[:lock_version]}

              if id_set.empty?
                # All records got filtered out, so there's nothing to do.
                next
              end

              records = record_type.filter(:id => id_set.map(&:id)).all

              # Delete old versions of the records we're about to index
              mapdb[:index_feed].filter(:record_uri => records.map(&:uri)).delete

              record_type.sequel_to_jsonmodel(records).each do |record|
                mapped_json = map_record(record.id, record.to_hash(:trusted)).to_json
                mapdb[:index_feed].insert(:record_type => record.jsonmodel_type,
                                          :record_uri => record.uri,
                                          :repo_id => repo.id,
                                          :record_id => record.id,
                                          :lock_version => record.lock_version,
                                          :blob => Sequel::SQL::Blob.new(gzip(mapped_json)))
                did_something = true
              end

              Log.info("Added #{records.count} #{record_type} records to MAP index feed")
            end
          end

          @state.set_last_mtime(repo.id, record_type_name, now)
        end
      end
    end
  end


  def self.start
    Thread.new do
      IndexFeedThread.new.call
    end
  end


  private

  # Map our jsonmodel into something ready for Solr
  def map_record(id, jsonmodel)
    solr_doc = {
      'id' => jsonmodel['jsonmodel_type'] + ':' + id.to_s,
      'uri' => jsonmodel['uri'],
      'primary_type' => jsonmodel['jsonmodel_type'],
      'title' => jsonmodel['display_string'] || jsonmodel['title'],
      'qsa_id' => jsonmodel['qsa_id'].to_s,
    }

    if jsonmodel['jsonmodel_type'] == 'agent_corporate_entity'
      solr_doc['title'] = jsonmodel['display_name']['sort_name']
    end

    if jsonmodel.has_key?('responsible_agency')
      solr_doc['responsible_agency'] = jsonmodel['responsible_agency']['ref']
    end

    if jsonmodel.has_key?('recent_responsible_agencies')
      solr_doc['recent_responsible_agencies'] = jsonmodel['recent_responsible_agencies'].map{|r| r['ref']}
    end

    if jsonmodel.has_key?('other_responsible_agencies')
      solr_doc['other_responsible_agencies'] = jsonmodel['other_responsible_agencies'].map{|r| r['ref']}
    end

    if jsonmodel.has_key?('physical_representations')
      solr_doc['physical_representations'] = jsonmodel['physical_representations'].map {|rep| rep['uri']}
    end

    if jsonmodel.has_key?('digital_representations')
      solr_doc['digital_representations'] = jsonmodel['digital_representations'].map {|rep| rep['uri']}
    end

    solr_doc
  end


  def gzip(bytestring)
    Zlib::Deflate.deflate(bytestring)
  end

end
