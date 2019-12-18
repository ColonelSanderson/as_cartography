class AgencyReadingRoomRequestsController < ApplicationController

  RESOLVES = ['requested_item', 'requesting_agency']

  include ApplicationHelper

  # TODO: review access controls for these endpoints
  set_access_control  "view_repository" => [:show]

  def show
    @reading_room_request = JSONModel(:agency_reading_room_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
    render :template => 'reading_room_requests/show'
  end

  def current_record
    @reading_room_request
  end
end
