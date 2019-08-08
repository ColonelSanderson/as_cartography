module FileIssueHelpers
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # We need to build URIs for representations, but the MAP doesn't have any
    # notion of an active repository.  So, we work out the repository that each
    # referenced representation belongs to and work backwards from that.
    def repo_ids_for_items(file_issue_request_items)
      aspace_models = {}

      file_issue_request_items = file_issue_request_items.values.flatten

      # Resolve JSONModel types back to ASModel classes
      file_issue_request_items.each do |item|
        aspace_record_type = item[:aspace_record_type]
        aspace_record_id = item[:aspace_record_id]

        aspace_models[aspace_record_type] ||= ASModel.all_models.find {|m| m.my_jsonmodel(true) && (m.my_jsonmodel(true).record_type == aspace_record_type)}
      end

      # Load repo_ids of our records
      repo_id_by_aspace_record = {}

      DB.open do |db|
        file_issue_request_items.group_by {|item| item[:aspace_record_type]}.each do |group_record_type, item_group|
          model = aspace_models.fetch(group_record_type)

          # Hit the model table directly to avoid repo scoping constraints
          db[model.table_name]
            .filter(:id => item_group.map {|item| item[:aspace_record_id]})
            .select(:id, :repo_id)
            .each do |row|
            key = {:aspace_record_type => group_record_type, :aspace_record_id => row[:id]}
            repo_id_by_aspace_record[key] = row[:repo_id]
          end
        end
      end

      # Finally, map our items back to the repositories containing them
      file_issue_request_items.map {|item|
        key = {:aspace_record_type => item[:aspace_record_type],
               :aspace_record_id => item[:aspace_record_id]}

        [item[:id], repo_id_by_aspace_record.fetch(key)]
      }.to_h
    end
  end
end
