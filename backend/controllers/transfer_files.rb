class ArchivesSpaceService < Sinatra::Base

  # FIXME # .permissions([:list_proposals])
  Endpoint.get('/transfer_files')
    .description("Stream a file associated with a transfer")
    .params(["key", String, "The file key to fetch"])
    .permissions([])
    .returns([200, "[(bytes)]"]) \
  do
    [
      200,
      {"Content-Type" => "application/octet-stream"},
      ByteStorage.get.to_enum(:get_stream, params[:key])
    ]
  end

  Endpoint.get('/transfer_files/validate')
    .description("Validate an import metadata file")
    .params(["key", String, "The file key to validate"],
            ["repo_id", :repo_id, "The active repository"])
    .permissions([])
    .returns([200, "{valid: [boolean], errors: [string]}"]) \
  do
    begin
      import_file = Tempfile.new(['transfer_files', '.xlsx'])
      begin
        ByteStorage.get.get_stream(params[:key]) do |chunk|
          import_file << chunk
        end

        import_file.close

        errors = Validator.validate(import_file.path, params[:repo_id])

        json_response({'valid' => errors.empty?, 'errors' => errors})
      ensure
        import_file.unlink
      end
    rescue XLSXStreamingReader::XLSXFileNotReadable
      json_response({'valid' => false, 'errors' => ["ERROR - Import file must be a valid XLSX file"]})
    rescue
      Log.exception($!)
      json_response({'valid' => false, 'errors' => ["SYSTEM ERROR - Could not validate this file"]})
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
      ByteStorage.get.store(params[:replacement_file].tempfile, params[:key])

      mapdb[:transfer_file].filter(:key => params[:key]).update(:filename => params[:filename],
                                                                :mime_type => params[:replacement_file].type)
    end

    json_response({"status" => "updated"})
  end
end
