class SearchRequestQuoteGenerator < QuoteGenerator

  register('Search Request', :search_request)

  add_rule('Search Request Search') do |search_request|
    # per 15 min - don't have the data so set to zero
    0
  end

end
