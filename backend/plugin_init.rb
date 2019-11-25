# register models for history
begin
  [
   Transfer,
   TransferProposal,
   FileIssue,
   FileIssueRequest,
   SearchRequest
  ].each do |model|
    History.register_model(model)
    History.add_model_map(model, :last_modified_by => :modified_by,
                                 :user_mtime => proc {|obj| obj.modified_time})
  end
rescue NameError
  Log.info("Unable to register MAP models for history. Please install the as_history plugin")
end

# register models for qsa_ids
require_relative '../common/qsa_id_registrations'

# add new movement context models
require_relative '../common/movement_contexts'

MAPDB.connect

require_relative 'index_feed/map_indexer_feed_profile'

ArchivesSpaceService.plugins_loaded_hook do
  if AppConfig.has_key?(:map_index_feed_enabled) && AppConfig[:map_index_feed_enabled] == false
    Log.info("MAP indexer thread will not be started as AppConfig[:map_index_feed_enabled] is false")
  else
    Log.info("Starting MAP indexer...")
    IndexFeedThread.new("plugin_qsauatmap", MAPIndexerFeedProfile.new).start
  end
end
