class TransferProposalsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show]


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "transfer_proposal", {"sort" => "title_sort asc", "facet[]" => Plugins.search_facets_for_type(:transfer_proposal)}.merge(params_for_backend_search))
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/transfer_proposals"
        csv_response( uri, search_params )
      }
    end
  end


  def show
    @transfer_proposal = JSONModel(:transfer_proposal).find(params[:id], find_opts.merge('resolve[]' => ['agency']))
  end


  def current_record
    @transfer_proposal
  end

end
