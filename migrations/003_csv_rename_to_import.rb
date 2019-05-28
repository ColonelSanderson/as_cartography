require 'db/migrations/utils'

Sequel.migration do

  up do
    enum_id = self[:enumeration].filter(:name => 'transfer_file_role').first[:id]
    self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'CSV').update(:value => 'IMPORT')
  end

end
