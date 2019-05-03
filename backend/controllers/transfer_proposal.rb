class ArchivesSpaceService < Sinatra::Base

  # FIXME # .permissions([:list_proposals])
  Endpoint.get('/transfer_proposals')
    .description("List transfer proposals")
    .permissions([])
    .paginated(true)
    .returns([200, "[(:transfer_proposal)]"]) \
  do
    handle_listing(TransferProposal, params)
  end

  Endpoint.get('/transfer_proposals/:id')
    .description("Get a transfer proposal by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:transfer_proposal)"],
             [404, "Not found"]) \
  do
    json = TransferProposal.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

end
