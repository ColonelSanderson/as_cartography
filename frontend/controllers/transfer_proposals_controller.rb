class TransferProposalsController < ApplicationController

  RESOLVES = ['agency', 'transfer']

  set_access_control  "view_repository" => [:index, :show, :edit, :update, :approve, :cancel]


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
    proposal_uri = JSONModel(:transfer_proposal).uri_for(params[:proposal_id])
    response = JSONModel::HTTP.post_form("#{proposal_uri}/approve")

    if response.code == '200'
      flash[:info] = I18n.t('transfer_proposal._frontend.messages.approve_succeeded')
      transfer = JSONModel(:transfer).from_hash(ASUtils.json_parse(response.body))
      resolver = Resolver.new(transfer.uri)
      redirect_to(resolver.view_uri)
    else
      flash[:error] = I18n.t('transfer_proposal._frontend.errors.approval_failed')
      resolver = Resolver.new(proposal_uri)
      redirect_to(resolver.view_uri)
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
    @transfer_proposal = JSONModel(:transfer_proposal).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end


  def edit
    @transfer_proposal = JSONModel(:transfer_proposal).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end


  def update
    # Fetch the current version
    updated = JSONModel(:transfer_proposal).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))

    # Apply metadata changes
    [:title, :estimated_quantity, :lock_version].each do |prop|
      updated[prop] = params[:transfer_proposal][prop]
    end

    updated[:series] = updated[:series].zip(params[:transfer_proposal][:series]).map{|old, new| old.merge(new)}

    params[:transfer_proposal] = updated

    handle_crud(:instance => :transfer_proposal,
                :model => JSONModel(:transfer_proposal),
                :obj => JSONModel(:transfer_proposal).find(params[:id], find_opts.merge('resolve[]' => RESOLVES)),
                :on_invalid => ->(){
                  render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("transfer_proposal._frontend.messages.updated", JSONModelI18nWrapper.new(:transfer => @transfer_proposal))
                  redirect_to :controller => :transfer_proposals, :action => :show, :id => id
                })
  end

  def current_record
    @transfer_proposal
  end

end
