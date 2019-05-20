require 'spec_helper'

describe 'Cartography Quotes' do

  it 'already has services defined' do
    expect(ChargeableService.filter(:name => 'File Issue Physical').count).to eq(1)
    expect(ChargeableService.filter(:name => 'File Issue Digital').count).to eq(1)
  end


  it 'can generate quotes' do

    fip = {
      'urgent' => true,
      'requested_representations' => [
                                      {'ref' => '/repositories/2/physical_representations/1'},
                                      {'ref' => '/repositories/2/physical_representations/2'},
                                      {'ref' => '/repositories/2/digital_representations/1'},
                                      {'ref' => '/repositories/2/physical_representations/3'},
                                      {'ref' => '/repositories/2/digital_representations/2'},
                                     ]
    }

    # FIXME: actual tests please
    physical_quote = FileIssuePhysicalQuoteGenerator.quote_for(fip)
    pp physical_quote.to_hash

    digital_quote = FileIssueDigitalQuoteGenerator.quote_for(fip)
    pp digital_quote.to_hash

  end
end
