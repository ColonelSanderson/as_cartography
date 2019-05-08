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

  Endpoint.post("/transfer_files/replace")
  .description("Replace a file stream with a new one")
  .params(["key", String, "The file key that will be replaced"],
          ["filename", String, "The new filename"],
          ["replacement_file", UploadFile, "The new file stream"])
  .permissions([])
  .returns([200, "success"]) \
  do
    MAPDB.open do |mapdb|
      existing_file = mapdb[:file][:key => params[:key]]

      # Sanity check our key
      raise NotFoundException.new("No key found for #{params[:key]}") unless existing_file

      mapdb[:file].filter(:key => params[:key]).update(:blob => Sequel::SQL::Blob.new(params[:replacement_file].tempfile.read))

      mapdb[:transfer_file].filter(:key => params[:key]).update(:filename => params[:filename],
                                                                :mime_type => params[:replacement_file].type)
    end

    json_response({"status" => "updated"})
  end
end
