require 'db/migrations/utils'

Sequel.migration do

  up do
    create_editable_enum('transfer_file_role', ['CSV', 'RAP', 'OTHER'])
  end
end
