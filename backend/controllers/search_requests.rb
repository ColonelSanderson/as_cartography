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

end
