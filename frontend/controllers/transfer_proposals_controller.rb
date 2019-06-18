class TransferProposalsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :approve, :cancel]


  def index
    respond_to do |format|
      format.html {
        params = {"sort" => "title_sort asc", "facet[]" => Plugins.search_facets_for_type(:transfer_proposal)}.merge(params_for_backend_search)

        # Exclude inactive transfer proposals.
        raise "Unexpected pre-existing filter" if params['filter']
        params['filter'] = JSONModel(:advanced_query).from_hash('query' => {
                                                                  'jsonmodel_type' => 'field_query',
                                                                  'negated' => true,
                                                                  'field' => 'transfer_status_u_sstr',
                                                                  'value' => 'INACTIVE',
                                                                  'literal' => true,
                                                                })
                             .to_json

        @search_data = Search.for_type(session[:repo_id], "transfer_proposal", params)
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/transfer_proposals"
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
      flash[:error] = I18n.t('transfer_proposal._frontend.errors.approval_failed')
    end
  end


  def cancel
    response = JSONModel::HTTP.post_form(JSONModel(:transfer_proposal).uri_for("#{params[:proposal_id]}/cancel"))

    if response.code == '200'
      flash[:info] = I18n.t('transfer_proposal._frontend.messages.cancel_succeeded')
    else
      flash[:error] = I18n.t('transfer_proposal._frontend.errors.cancel_failed')
    end

    redirect_to(:controller => :transfer_proposals, :action => :show, :id => params[:proposal_id])
  end


  def show
    @transfer_proposal = JSONModel(:transfer_proposal).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'transfer']))
  end


  def current_record
    @transfer_proposal
  end

end
