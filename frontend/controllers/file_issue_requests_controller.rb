class FileIssueRequestsController < ApplicationController

  RESOLVES = ['agency', 'file_issue', 'requested_representations']

  set_access_control  "view_repository" => [:index, :show, :edit, :update, :generate_physical_quote]

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
    @file_issue_request = JSONModel(:file_issue_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def edit
    @file_issue_request = JSONModel(:file_issue_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def update
    updated_representations = params[:file_issue_request][:requested_representations].map {|elt| elt.fetch('ref')}

    # Fetch the current version
    updated = JSONModel(:file_issue_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))

    # Relink representations as requested
    updated.requested_representations.zip(updated_representations) do |requested_representation, new_ref|
      requested_representation['ref'] = new_ref
    end

    params[:file_issue_request] = updated

    handle_crud(:instance => :file_issue_request,
                :model => JSONModel(:file_issue_request),
                :obj => JSONModel(:file_issue_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES)),
                :on_invalid => ->(){
                  render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("file_issue_request._frontend.messages.updated", JSONModelI18nWrapper.new(:transfer => @file_issue_request))
                  redirect_to :controller => :file_issue_requests, :action => :show, :id => id
                })
  end

  def current_record
    @file_issue_request
  end

  def generate_physical_quote
    redirect_to :controller => :file_issue_requests, :action => :show, :id => params[:id]
  end
end
