class TransferFilesController < ApplicationController

  set_access_control  "view_repository" => [:show, :validate]


  def show
    filename = params[:filename]

    self.response.headers["Content-Type"] = params[:mime_type]
    self.response.headers["Content-Disposition"] = "attachment; filename=#{filename}"
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/transfer_files", :key => params[:key]) do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end

  def validate
    render :json => JSONModel::HTTP.get_json("/transfer_files/validate", :key => params[:key], :repo_id => session[:repo_id])
  end

end
