class SearchRequestsController < ApplicationController

  RESOLVES = ['agency', 'quote']

  set_access_control  "view_repository" => [:index, :show, :edit, :update, :cancel, :approve, :close, :reopen, :save_quote, :issue_quote, :withdraw_quote, :download_file, :upload_file]

  def index
    respond_to do |format|
      format.html {
        params = {"sort" => "create_time desc", "facet[]" => Plugins.search_facets_for_type(:search_request)}.merge(params_for_backend_search)

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

        @search_data = Search.for_type(session[:repo_id], "search_request", params.merge('facet[]' => ['search_request_status_u_sstr']))
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

    updated.files = Array(params[:search_request][:files]).map {|file|
      {
        'filename': file.fetch(:filename),
        'key': file.fetch(:key),
        'mime_type': file.fetch(:mime_type),
      }
    }

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
    response = JSONModel::HTTP.post_form(JSONModel(:search_request).uri_for("#{params[:id]}/cancel"))

    if response.code == '200'
      flash[:info] = I18n.t('search_request._frontend.messages.cancel_succeeded')
    else
      flash[:error] = I18n.t('search_request._frontend.errors.cancel_failed')
    end

    redirect_to(:controller => :search_requests, :action => :show, :id => params[:id])
  end

  def approve
    response = JSONModel::HTTP.post_form(JSONModel(:search_request).uri_for("#{params[:id]}/approve"))

    if response.code == '200'
      flash[:info] = I18n.t('search_request._frontend.messages.approve_succeeded')
    else
      flash[:error] = I18n.t('search_request._frontend.errors.approve_failed')
    end

    redirect_to(:controller => :search_requests, :action => :show, :id => params[:id])
  end

  def close
    response = JSONModel::HTTP.post_form(JSONModel(:search_request).uri_for("#{params[:id]}/close"))

    if response.code == '200'
      flash[:info] = I18n.t('search_request._frontend.messages.close_succeeded')
    else
      flash[:error] = I18n.t('search_request._frontend.errors.close_failed')
    end

    redirect_to(:controller => :search_requests, :action => :show, :id => params[:id])
  end

  def reopen
    response = JSONModel::HTTP.post_form(JSONModel(:search_request).uri_for("#{params[:id]}/reopen"))

    if response.code == '200'
      flash[:info] = I18n.t('search_request._frontend.messages.reopen_succeeded')
    else
      flash[:error] = I18n.t('search_request._frontend.errors.reopen_failed')
    end

    redirect_to(:controller => :search_requests, :action => :show, :id => params[:id])
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

  def issue_quote
    response = JSONModel::HTTP.post_form("/search_requests/#{params[:id]}/issue_quote", {})

    if response.code == '200'
      flash[:success] = I18n.t("search_request._frontend.messages.quote_issue_success")
    else
      flash[:error] = I18n.t("search_request._frontend.messages.quote_issue_error", response.body)
    end

    redirect_to :controller => :search_requests, :action => :show, :id => params[:id]
  end

  def withdraw_quote
    response = JSONModel::HTTP.post_form("/search_requests/#{params[:id]}/withdraw_quote", {})

    if response.code == '200'
      flash[:success] = I18n.t("search_request._frontend.messages.quote_withdraw_success")
    else
      flash[:error] = I18n.t("search_request._frontend.messages.quote_withdraw_error", response.body)
    end

    redirect_to :controller => :search_requests, :action => :show, :id => params[:id]
  end

  def download_file
    self.response.headers["Content-Type"] = params[:mime_type]
    self.response.headers["Content-Disposition"] = "attachment; filename=#{params[:filename]}"
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/search_requests/#{params[:id]}/view_file",
                             :key => params[:key]) do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end

  def upload_file
    response = JSONModel::HTTP.post_form("/search_requests/#{params[:id]}/upload_file",
                                         {
                                           :file => UploadIO.new(params[:file].tempfile,
                                                                 params[:file].content_type,
                                                                 params[:file].original_filename),
                                         },
                                         :multipart_form_data)

    raise unless response.code == '200'

    json = ASUtils.json_parse(response.body)

    render :json => {
      "status" => "success",
      "filename" => params[:file].original_filename,
      "mime_type" => params[:file].content_type,
      "key" => json['key'],
    }, :status => '200'
  end


  # FIXME: i've added one of these to each of the map controllers
  #        there's probably a cleaner, more general way to do it
  helper_method :status_label
  def status_label(status)
    @status_map ||= {
      'INACTIVE' => 'info',
      'SUBMITTED' => 'primary',
      'OPEN' => 'warning',
      'CLOSED' => 'success',
      'CANCELLED_BY_QSA' => 'danger',
      'CANCELLED_BY_AGENCY' => 'danger',
    }

    "<span class=\"label label-#{@status_map[status]}\">#{status}</span>".html_safe
  end
end
