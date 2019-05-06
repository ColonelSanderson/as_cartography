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
