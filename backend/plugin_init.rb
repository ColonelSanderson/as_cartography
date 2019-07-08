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
                                 :user_mtime => obj.modified_time)
  end
rescue NameError
  Log.info("Unable to register Mandate and Function for history. Please install the as_history plugin")
end

MAPDB.connect

require_relative 'index_feed/index_feed_thread'

IndexFeedThread.start
