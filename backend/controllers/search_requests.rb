class ArchivesSpaceService < Sinatra::Base

  # FIXME Need permissions on these too
  Endpoint.get('/search_requests')
    .description("List search requests")
    .permissions([])
    .paginated(true)
    .returns([200, "[(:search_request)]"]) \
  do
    handle_listing(SearchRequest, params)
  end

  Endpoint.get('/search_requests/:id')
    .description("Get a search request by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:search_request)"],
             [404, "Not found"]) \
  do
    json = SearchRequest.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.post('/search_requests/:id')
    .description("Update a File Issue")
    .params(["id", :id],
            ["search_request", JSONModel(:search_request), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(SearchRequest, params[:id], params[:search_request])
  end

  Endpoint.post('/search_requests/:id/cancel')
    .description("Cancel a given request")
    .params(["id", :id])
    .permissions([])
    .returns([200, "cancel succeeded"]) \
  do
    MAPDB.transaction do
      SearchRequest.get_or_die(params[:id]).cancel!
      json_response('status' => 'cancelled')
    end
  end

  Endpoint.post('/search_requests/:id/approve')
    .description("Approve a given request")
    .params(["id", :id])
    .permissions([])
    .returns([200, "approve succeeded"]) \
  do
    MAPDB.transaction do
      SearchRequest.get_or_die(params[:id]).approve!
      json_response('status' => 'approved')
    end
  end

  Endpoint.post('/search_requests/:id/close')
         .description("Close a given request")
         .params(["id", :id])
         .permissions([])
         .returns([200, "close succeeded"]) \
  do
    MAPDB.transaction do
      SearchRequest.get_or_die(params[:id]).close!
      json_response('status' => 'closed')
    end
  end

  Endpoint.post('/search_requests/:id/reopen')
    .description("Reopen a given request")
    .params(["id", :id])
    .permissions([])
    .returns([200, "reopen succeeded"]) \
  do
    MAPDB.transaction do
      SearchRequest.get_or_die(params[:id]).reopen!
      json_response('status' => 'reopened')
    end
  end

  Endpoint.post('/search_requests/:id/issue_quote')
    .description("Issue a quote")
    .params(["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    obj = SearchRequest.get_or_die(params[:id])

    obj.issue_quote!

    json_response({:message => 'Quote issued'})
  end

  Endpoint.post('/search_requests/:id/withdraw_quote')
    .description("Withdraw a previously issued quote")
    .params(["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    obj = SearchRequest.get_or_die(params[:id])

    obj.withdraw_quote!

    json_response({:message => 'Quote issued'})

  end

  Endpoint.post("/search_requests/:id/upload_file")
    .description("Upload a search request file")
    .params(["file", UploadFile, "The file stream"])
    .permissions([])
    .returns([200, '{"key": "<opaque key>"}']) \
  do
    key = SearchRequestFileStore.new.store_file(params[:file])

    json_response({"key" => key})
  end

  Endpoint.get("/search_requests/:id/view_file")
    .description("Fetch a search request file")
    .params(["id", :id])
    .params(["key", String, "The key returned by a previous call to upload_file"])
    .permissions([])
    .returns([200, 'application/octet-stream']) \
  do
    [
      200,
      {"Content-Type" => "application/octet-stream"},
      SearchRequestFileStore.new.to_enum(:get_file, params[:key])
    ]
  end
end
