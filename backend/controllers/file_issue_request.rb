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

  Endpoint.post('/file_issue_requests/:id')
    .description("Update a File Issue Request")
    .params(["id", :id],
            ["file_issue_request", JSONModel(:file_issue_request), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(FileIssueRequest, params[:id], params[:file_issue_request])
  end

  Endpoint.post('/file_issue_requests/:id/generate_quote/:type')
    .description("Generate a quote for a File Issue Request")
    .params(["id", :id],
            ["type", String, "The type of quote (physical or digital)"])
    .permissions([])
    .returns([200, :updated]) \
  do
    json = FileIssueRequest.to_jsonmodel(params[:id])
    type = params[:type].start_with?('p') ? :physical : :digital
    generator = type == :physical ? FileIssuePhysicalQuoteGenerator : FileIssueDigitalQuoteGenerator
    quote = generator.quote_for(json)
    json["#{type}_quote"] = {'ref' => quote.uri}
    handle_update(FileIssueRequest, params[:id], json)
  end

  Endpoint.post('/file_issue_requests/:id/issue_quote/:type')
    .description("Issue a quote for a File Issue Request")
    .params(["id", :id],
            ["type", String, "The type of quote (physical or digital)"])
    .permissions([])
    .returns([200, :updated]) \
  do
    json = FileIssueRequest.to_jsonmodel(params[:id])

    ServiceQuote[JSONModel.parse_reference(json["#{params[:type]}_quote"]['ref'])[:id]].issue

    fir = FileIssueRequest[params[:id]]
    fir["#{params[:type]}_request_status"] = 'QUOTE_PROVIDED'
    fir.save

    json_response({:message => 'Quote issued'})
  end

  Endpoint.post('/file_issue_requests/:id/withdraw_quote/:type')
    .description("Withdraw a previously issued quote for a File Issue Request")
    .params(["id", :id],
            ["type", String, "The type of quote (physical or digital)"])
    .permissions([])
    .returns([200, :updated]) \
  do
    json = FileIssueRequest.to_jsonmodel(params[:id])

    ServiceQuote[JSONModel.parse_reference(json["#{params[:type]}_quote"]['ref'])[:id]].withdraw

    fir = FileIssueRequest[params[:id]]
    fir["#{params[:type]}_request_status"] = 'QUOTE_REQUESTED'
    fir.save

    json_response({:message => 'Quote withdrawn'})
  end

  Endpoint.post('/file_issue_requests/:id/cancel')
    .description("Cancel a given request")
    .params(["id", :id],
            ["cancel_target", String, "The part of the request to cancel ('physical', 'digital' or 'both')"])
    .permissions([])
    .returns([200, "cancel succeeded"]) \
  do
    raise "Invalid cancel target" unless ['physical', 'digital', 'both'].include?(params[:cancel_target])

    MAPDB.transaction do
      FileIssueRequest[params[:id]].cancel!(params[:cancel_target])

      json_response('status' => 'cancelled')
    end
  end

end
