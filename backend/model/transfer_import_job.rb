class TransferImportJob < BatchImportRunner

  register_for_job_type('transfer_import_job',
                        :create_permissions => :import_records,
                        :cancel_permissions => :cancel_importer_job)

  def run
    super

    begin
      # If we succeeded, update the transfer to reflect the import status.
      transfer_id = @json.job.fetch('opts', {}).fetch('transfer_id', nil)

      return unless transfer_id

      RequestContext.open(:current_username => @job.owner.username,
                          :repo_id => @job.repo_id) do
        transfer_obj = Transfer[transfer_id]
        transfer_json = Transfer.sequel_to_jsonmodel([transfer_obj])[0]

        transfer_json.checklist_metadata_imported = true
        transfer_obj.update_from_json(transfer_json)
      end
    rescue
      Log.error("Unexpected failure in Transfer import: #{$!}")
      Log.exception($!)

      raise $!
    end

  end
end
