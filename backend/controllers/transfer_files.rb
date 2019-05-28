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

  Endpoint.get('/transfer_files/validate')
    .description("Validate an import metadata file")
    .params(["key", String, "The file key to validate"])
    .permissions([])
    .returns([200, "{valid: [boolean], errors: [string]}"]) \
  do
    MAPDB.open do |mapdb|
      # All of this will be rejiggered when we switch to S3, so just spamming it in here for now...
      import_file = Tempfile.new(['transfer_files', '.xlsx'])
      begin
        import_file.write(mapdb[:file][:key => params[:key]][:blob])
        import_file.close

        errors = []
        import_validator = MapValidator.new
        import_validator.run_validations(import_file.path, import_validator.sample_validations)
        import_validator.notifications.notification_list.each do |notification|
          if notification.source.to_s.empty?
            errors << "#{notification.type} - #{notification.message}"
          else
            errors << "#{notification.type} - [#{notification.source}] #{notification.message}"
          end
        end

        json_response({'valid' => errors.empty?, 'errors' => errors})
      ensure
        import_file.unlink
      end
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
