# NOTE: We're using load here because IndexerCommon has already called require()
# on our file, but did so before the PeriodicIndexer class had been loaded.
# Since we depend on it, we use a conditional to skip doing anything on the
# initial require(), and then reload the file from here once we know
# PeriodicIndexer is available.
#
load File.join(File.dirname(__FILE__), "qsa_map_indexer.rb")
