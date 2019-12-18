class ArchivesSpaceService < Sinatra::Base

  # FIXME Need permissions on these too
  Endpoint.get('/agency_reading_room_requests')
    .description("List reading room requests")
    .permissions([])
    .paginated(true)
    .returns([200, "[(:agency_reading_room_request)]"]) \
  do
    handle_listing(AgencyReadingRoomRequest, params)
  end

  Endpoint.get('/agency_reading_room_requests/:id')
    .description("Get a reading room request by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:agency_reading_room_request)"],
             [404, "Not found"]) \
  do
    json = AgencyReadingRoomRequest.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.post('/agency_reading_room_requests/:id/set_status')
    .description("Update the request status")
    .params(["id", :id],
            ["status", String, "New status"])
    .permissions([])
    .returns([200, "(:success)"],
             [404, "Not found"]) \
  do
    request = AgencyReadingRoomRequest.get_or_die(params[:id])
    request.set_status(params[:status])
    json_response({:status => "success"})
  end
end
