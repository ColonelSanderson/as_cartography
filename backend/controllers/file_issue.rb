class ArchivesSpaceService < Sinatra::Base

  # FIXME Need permissions on these too
  Endpoint.get('/file_issues')
    .description("List file issues")
    .permissions([])
    .paginated(true)
    .returns([200, "[(:file_issue)]"]) \
  do
    handle_listing(FileIssue, params)
  end

  Endpoint.get('/file_issues/:id')
    .description("Get a file issue by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:file_issue)"],
             [404, "Not found"]) \
  do
    json = FileIssue.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.post('/file_issues/:id')
    .description("Update a File Issue")
    .params(["id", :id],
            ["file_issue", JSONModel(:file_issue), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(FileIssue, params[:id], params[:file_issue])
  end

end
