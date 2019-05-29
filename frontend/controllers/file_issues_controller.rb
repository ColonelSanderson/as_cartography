class FileIssuesController < ApplicationController

  RESOLVES = ['agency', 'requested_representations']

  set_access_control  "view_repository" => [:index, :show, :edit, :update]

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "file_issue", {"sort" => "title_sort asc", "facet[]" => Plugins.search_facets_for_type(:file_issue)}.merge(params_for_backend_search))
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/file_issues"
        csv_response( uri, search_params )
      }
    end
  end


  def show
    @file_issue = JSONModel(:file_issue).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def edit
    @file_issue = JSONModel(:file_issue).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def update
    # Fetch the current version
    updated = JSONModel(:file_issue).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))

    # update the representations
    updated.requested_representations.zip(params[:file_issue][:requested_representations].map{|_, values| values}) do |requested_representation, form|
      requested_representation['dispatch_date'] = form['dispatch_date']
      requested_representation['dispatched_by'] = form['dispatched_by']
      requested_representation['expiry_date'] = form['expiry_date']
      requested_representation['returned_date'] = form['returned_date']
      requested_representation['received_by'] = form['received_by']
    end

    params[:file_issue] = updated

    handle_crud(:instance => :file_issue,
                :model => JSONModel(:file_issue),
                :obj => JSONModel(:file_issue).find(params[:id], find_opts.merge('resolve[]' => RESOLVES)),
                :on_invalid => ->(){
                  render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("file_issue._frontend.messages.updated", JSONModelI18nWrapper.new(:transfer => @file_issue))
                  redirect_to :controller => :file_issues, :action => :show, :id => id
                })
  end

  def current_record
    @file_issue
  end
end