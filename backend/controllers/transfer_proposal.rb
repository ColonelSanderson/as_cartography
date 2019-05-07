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

  Endpoint.post('/transfer_proposals/:id/approve')
    .description("Create a new transfer from a given proposal")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:transfer)"]) \
  do
    MAPDB.transaction do
      obj = Transfer.create_from_proposal(params[:id])

      json_response(Transfer.to_jsonmodel(obj))
    end
  end

  Endpoint.post('/transfer_proposals/:id/cancel')
    .description("Cancel a given proposal")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:transfer)"]) \
  do
    MAPDB.transaction do
      TransferProposal[params[:id]].cancel!

      json_response('status' => 'cancelled')
    end
  end

end
