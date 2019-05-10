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
    .description("Validate a CSV metadata file")
    .params(["key", String, "The file key to validate"])
    .permissions([])
    .returns([200, "{valid: [boolean], errors: [string]}"]) \
  do
    MAPDB.open do |mapdb|
      # All of this will be rejiggered when we switch to S3, so just spamming it in here for now...
      csv_file = Tempfile.new
      begin
        csv_file.write(mapdb[:file][:key => params[:key]][:blob])
        csv_file.close

        # Sanity check that the file we're looking at is CSV.  Maybe the CSV validator should handle this?
        believable_csv = File.open(csv_file, "rb") do |csv|
          csv.read(256).bytes.all? {|b| b >= 32}
        end

        if believable_csv
          errors = []
          csv_validator = MapValidator.new
          csv_validator.run_validations(csv_file, csv_validator.sample_validations)
          csv_validator.notifications.notification_list.each do |notification|
            errors << "[#{notification.type}](#{notification.source}): #{notification.message}"
          end

          json_response({'valid' => errors.empty?, 'errors' => errors})
        else
          json_response({'valid' => false, 'errors' => ["Does not appear to be a comma-separated file"]})
        end
      ensure
        csv_file.unlink
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
