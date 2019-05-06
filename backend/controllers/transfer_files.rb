class ArchivesSpaceService < Sinatra::Base

  # FIXME # .permissions([:list_proposals])
  Endpoint.get('/transfer_files')
    .description("Stream a file associated with a transfer")
    .params(["key", String, "The file key to fetch"])
    .permissions([])
    .returns([200, "[(bytes)]"]) \
  do
    MAPDB.open do |mapdb|
      [
        200,
        {"Content-Type" => "application/octet-stream"},
        mapdb[:file][:key => params[:key]][:blob]
      ]
    end
  end

end
