class ArchivesSpaceService < Sinatra::Base

  # FIXME: need permissions here as well
  Endpoint.get('/transfers')
    .description("List transfers")
    .permissions([])
    .paginated(true)
    .returns([200, "[(:transfer)]"]) \
  do
    handle_listing(Transfer, params)
  end

  Endpoint.post('/transfers/:id')
    .description("Update a Transfer")
    .params(["id", :id],
            ["transfer", JSONModel(:transfer), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(Transfer, params[:id], params[:transfer])
  end


  Endpoint.get('/transfers/:id')
    .description("Get a transfer by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:transfer)"],
             [404, "Not found"]) \
  do
    json = Transfer.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.post('/transfers/:id/import')
    .description("Import a transfer's CSV")
    .permissions([])
    .params(["id", String],
            ["repo_id", :repo_id])
    .returns([200, "(:ok)"]) \
  do
    transfer = Transfer[params[:id]]
    csv = transfer.csv

    tempfile = ASUtils.tempfile(csv[:filename])

    begin
      tempfile.write(csv[:data])
    ensure
      tempfile.close
    end

    job_hash = {
      "job_type" => "import_job",
      "jsonmodel_type" => "job",
      "job_params" => "",
      "job" => {
        "jsonmodel_type" => "import_job",
        "filenames" => [ csv[:filename] ],
        "import_type" => "agency_transfer",
        "opts" => {
          "transfer_id" => params[:id]
        }
      }
    }

    RequestContext.open(:repo_id => params[:repo_id]) do
      job = Job.create_from_json(JSONModel(:job).from_hash(job_hash), :user => current_user)

      job.add_file(tempfile)

      transfer.import_job_uri = job.uri
      transfer.save

      # bankrupcy declared!
      Thread.new do
        RequestContext.open(:repo_id => params[:repo_id]) do
          # give the insert transaction time to commit
          sleep 2
          j = Job[job.id]
          while !['completed', 'failed', 'canceled'].include?(j.status)
            sleep 2
            j.refresh
          end
          if j.status == 'completed'
            transfer.checklist_metadata_imported = 1
            transfer.save
          end
        end
      end

      json_response(:status => "submitted", :job => job.uri)
    end

  end

  Endpoint.get('/transfer_conversation')
    .description("A little more conversation...")
    .permissions([])
    .params(["handle_id", String]) \
    .returns([200, "(:conversation)"]) \
  do
    MAPDB.open do |mapdb|
      json_response(mapdb[:conversation].filter(:handle_id => Integer(params[:handle_id])).order(:id).all)
    end
  end

  Endpoint.post('/transfer_conversation')
    .description("A little more conversation...")
    .permissions([])
    .params(["handle_id", String],
            ["message", String]) \
    .returns([200, "(:ok)"]) \
  do
    MAPDB.open do |mapdb|
      mapdb[:conversation].insert(:handle_id => Integer(params[:handle_id]),
                                  :message => params[:message].strip,
                                  :create_time => Time.now.to_f * 1000,
                                  :created_by => RequestContext.get(:current_username))
    end

    json_response(:status => "Created")
  end
end
