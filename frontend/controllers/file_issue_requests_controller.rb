class FileIssueRequestsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :edit, :update]


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "file_issue_request", {"sort" => "title_sort asc", "facet[]" => Plugins.search_facets_for_type(:file_issue_request)}.merge(params_for_backend_search))
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/file_issue_requests"
        csv_response( uri, search_params )
      }
    end
  end


  def show
    @file_issue_request = JSONModel(:file_issue_request).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'file_issue', 'requested_representations']))
  end

  def edit
    @file_issue_request = JSONModel(:file_issue_request).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'file_issue', 'requested_representations']))
  end

  def current_record
    @file_issue_request
  end

end
