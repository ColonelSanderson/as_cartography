class FileIssueDigitalQuoteGenerator < QuoteGenerator

  register('File Issue Digital', :file_issue_request)


  add_rule('File Issue Search') do |fir|
    # per 15 min - don't have the data so set to zero
    0
  end


  add_rule('File Issue Retrieval') do |fir|
    records(fir).length
  end


  add_rule('File Issue Digital Scanning 1-20') do |fir|
    # per page - don't have the data so set to zero
    0
  end


  add_rule('File Issue Digital Scanning 21-50') do |fir|
    # per order - don't have the data so set to zero
    0
  end


  add_rule('File Issue Digital Scanning 51-100') do |fir|
    # per order - don't have the data so set to zero
    0
  end


  add_rule('File Issue Digital Existing') do |fir|
    # per record - don't have the data so set to zero
    0
  end


  add_rule('File Issue Digital Urgent') do |fir|
    fir['urgent'] ? 1 : 0
  end


  def self.records(fir)
    fir['requested_representations'].select{|rep| JSONModel.parse_reference(rep['ref'])[:type] == 'digital_representation'}
  end
end
