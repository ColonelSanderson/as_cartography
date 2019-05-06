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

end
