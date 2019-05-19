class ArchivesSpaceService < Sinatra::Base

  # FIXME Need permissions on these too
  Endpoint.get('/file_issue_requests')
    .description("List file issue requests")
    .permissions([])
    .paginated(true)
    .returns([200, "[(:file_issue_request)]"]) \
  do
    handle_listing(FileIssueRequest, params)
  end

  Endpoint.get('/file_issue_requests/:id')
    .description("Get a file issue request by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:file_issue_request)"],
             [404, "Not found"]) \
  do
    json = FileIssueRequest.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

end
