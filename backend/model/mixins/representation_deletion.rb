module RepresentationDeletion

  def delete
    MAPDB.open do |map_db|
      map_db[:file_issue_item]
        .filter(:aspace_record_type => self.class.table_name.to_s)
        .filter(:aspace_record_id => self.id)
        .delete

      map_db[:file_issue_request_item]
        .filter(:aspace_record_type => self.class.table_name.to_s)
        .filter(:aspace_record_id => self.id)
        .delete
    end

    super
  end

end