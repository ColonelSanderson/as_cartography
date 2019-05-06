class TransfersController < ApplicationController

  # TODO: review access controls for these endpoints
  set_access_control  "view_repository" => [:index, :show, :approve]


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "transfer", {"sort" => "title_sort asc", "facet[]" => Plugins.search_facets_for_type(:transfer)}.merge(params_for_backend_search))
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/transfers"
        csv_response( uri, search_params )
      }
    end
  end

  def approve
    response = JSONModel::HTTP.post_form(JSONModel(:transfer_proposal).uri_for("#{params[:proposal_id]}/approve"))

    if response.code == '200'
      flash[:info] = I18n.t('transfer_proposal._frontend.messages.approve_succeeded')
      transfer = JSONModel(:transfer).from_hash(ASUtils.json_parse(response.body))
      resolver = Resolver.new(transfer.uri)
      redirect_to(resolver.view_uri)
    else
      # TODO: test this
      flash[:error] = I18n.t('transfer_proposal._frontend.errors.approval_failed')
    end
  end

  def show
    @transfer = JSONModel(:transfer).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'transfer_proposal']))
  end

  def current_record
    @transfer
  end
end
