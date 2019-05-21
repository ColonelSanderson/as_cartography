class FileIssuePhysicalQuoteGenerator < QuoteGenerator

  register('File Issue Physical', :file_issue_request)


  add_rule('File Issue Search') do |fir|
    # per 15 min - don't have the data so set to zero
    0
  end


  add_rule('File Issue Retrieval') do |fir|
    records(fir).length
  end


  add_rule('File Issue Delivery') do |fir|
    fir['deliver_to_reading_room'] ? 0 : 1
  end


  add_rule('File Issue Physical Urgent') do |fir|
    fir['urgent'] ? 1 : 0
  end


  def self.records(fir)
    fir['requested_representations'].select{|rep| rep['request_type'] == 'PHYSICAL'}
  end
end
