class SearchRequestsController < ApplicationController

  RESOLVES = ['agency', 'representations', 'quote']

  set_access_control  "view_repository" => [:index, :show, :edit, :update, :cancel, :approve, :save_quote]

  def index
    respond_to do |format|
      format.html {
        params = {"sort" => "title_sort asc", "facet[]" => Plugins.search_facets_for_type(:search_request)}.merge(params_for_backend_search)

        # Exclude drafts
        raise "Unexpected pre-existing filter" if params['filter']
        params['filter'] = JSONModel(:advanced_query).from_hash('query' => {
                                                                  'jsonmodel_type' => 'field_query',
                                                                  'negated' => true,
                                                                  'field' => 'search_request_draft_u_sbool',
                                                                  'value' => 'true',
                                                                  'literal' => true,
                                                                })
                             .to_json

        @search_data = Search.for_type(session[:repo_id], "search_request", params)
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/search_requests"
        csv_response( uri, search_params )
      }
    end
  end


  def show
    @search_request = JSONModel(:search_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def edit
    @search_request = JSONModel(:search_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def update
    # Fetch the current version
    updated = JSONModel(:search_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))

    updated.representations = params[:search_request][:representations].map {|elt| elt.fetch('ref')}.map do |ref|
      {'ref' => ref}
    end

    params[:search_request] = updated

    handle_crud(:instance => :search_request,
                :model => JSONModel(:search_request),
                :obj => JSONModel(:search_request).find(params[:id], find_opts.merge('resolve[]' => RESOLVES)),
                :on_invalid => ->(){
                  render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("search_request._frontend.messages.updated", JSONModelI18nWrapper.new(:search_request => @search_request))
                  redirect_to :controller => :search_requests, :action => :show, :id => id
                })
  end

  def cancel
    response = JSONModel::HTTP.post_form(JSONModel(:search_request).uri_for("#{params[:search_request_id]}/cancel"),
                                        'cancel_target' => params[:cancel_target])

    if response.code == '200'
      flash[:info] = I18n.t('search_request._frontend.messages.cancel_succeeded')
    else
      flash[:error] = I18n.t('search_request._frontend.errors.cancel_failed')
    end

    redirect_to(:controller => :search_requests, :action => :show, :id => params[:search_request_id])
  end

  def approve
    response = JSONModel::HTTP.post_form(JSONModel(:search_request).uri_for("#{params[:search_request_id]}/approve"),
                                        'approve_target' => params[:approve_target])

    if response.code == '200'
      flash[:info] = I18n.t('search_request._frontend.messages.approve_succeeded')
    else
      flash[:error] = I18n.t('search_request._frontend.errors.approve_failed')
    end

    redirect_to(:controller => :search_requests, :action => :show, :id => params[:search_request_id])
  end

  def current_record
    @search_request
  end

  def save_quote
    json = JSON.parse(params[:quote_json])

    url = URI("#{JSONModel::HTTP.backend_url}#{json['uri']}")

    response = JSONModel::HTTP.post_json(url, params[:quote_json])

    if response.code == '200'
      flash[:success] = I18n.t("search_request._frontend.messages.quote_save_success")
    else
      flash[:error] = I18n.t("search_request._frontend.messages.quote_save_error", response.body)
    end
    
    redirect_to :controller => :search_requests, :action => :show, :id => params[:id]
  end
end
