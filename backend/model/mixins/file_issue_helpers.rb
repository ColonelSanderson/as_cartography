module FileIssueHelpers
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # We need to build URIs for representations, but the MAP doesn't have any
    # notion of an active repository.  So, we work out the repository that each
    # referenced representation belongs to and work backwards from that.
    def repo_ids_for_items(file_issue_request_items)
      repo_id_by_item_id = {}
      aspace_models = {}

      file_issue_request_items.values.flatten.each do |item|
        aspace_record_type = item[:aspace_record_type]
        aspace_record_id = item[:aspace_record_id]

        aspace_models[aspace_record_type] ||= ASModel.all_models.find {|m| m.my_jsonmodel(true) && (m.my_jsonmodel(true).record_type == aspace_record_type)}

        repo_id_by_item_id[item[:id]] = aspace_models.fetch(aspace_record_type).any_repo[aspace_record_id][:repo_id]
      end

      repo_id_by_item_id
    end
  end
end
