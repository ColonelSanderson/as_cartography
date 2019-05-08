class TransfersController < ApplicationController

  # TODO: review access controls for these endpoints
  set_access_control  "view_repository" => [:index, :show, :edit, :update, :conversation, :conversation_send]


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

  def edit
    @transfer = JSONModel(:transfer).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'transfer_proposal']))
  end

  def update
    updated = JSONModel(:transfer).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'transfer_proposal']))

    [:title, :date_scheduled, :date_received, :quantity_received, :lock_version].each do |prop|
      updated[prop] = params[:transfer][prop]
    end

    [
      :checklist_metadata_received,
      :checklist_rap_received,
      :checklist_metadata_approved,
      :checklist_transfer_received,
    ].each do |prop|
      updated[prop] = (params[:transfer][prop] == "true")
    end

    params[:transfer] = updated

    handle_crud(:instance => :transfer,
                :model => JSONModel(:transfer),
                :obj => JSONModel(:transfer).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'transfer_proposal'])),
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("transfer._frontend.messages.updated", JSONModelI18nWrapper.new(:transfer => @transfer))
                  redirect_to :controller => :transfers, :action => :show, :id => id
                })
  end

  def show
    @transfer = JSONModel(:transfer).find(params[:id], find_opts.merge('resolve[]' => ['agency', 'transfer_proposal']))
  end

  def conversation
    render :json => JSONModel::HTTP.get_json("/transfer_conversation",
                                             :handle_id => params[:handle_id])
  end

  def conversation_send
    response = JSONModel::HTTP.post_form("/transfer_conversation",
                                         :handle_id => params[:handle_id],
                                         :message => params[:message])

    render :json => ASUtils.json_parse(response.body), :status => response.code
  end


  def current_record
    @transfer
  end
end
