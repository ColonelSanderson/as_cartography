module DelegateContacts
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      delegates_by_agent = build_delegate_map(objs)

      objs.zip(jsons).each do |obj, json|
        json['delegates'] = delegates_by_agent.fetch(obj.id, [])
      end

      jsons
    end

    def build_delegate_map(objs)
      delegate_by_id = {}

      aspace_agent_ids = objs.map(&:id)

      MAPDB.open do |mapdb|
        mapdb[:agency]
          .join(:agency_location, Sequel.qualify(:agency_location, :agency_id) => Sequel.qualify(:agency, :id))
          .join(:agency_user, Sequel.qualify(:agency_user, :agency_id) => Sequel.qualify(:agency, :id), Sequel.qualify(:agency_user, :agency_location_id) => Sequel.qualify(:agency_location, :id))
          .join(:user, Sequel.qualify(:user, :id) => Sequel.qualify(:agency_user, :user_id))
          .filter(Sequel.qualify(:agency_location, :top_level_location) => 1)
          .filter(Sequel.qualify(:agency, :aspace_agency_id) => aspace_agent_ids)
          .filter(Sequel.|({ Sequel.qualify(:agency_user, :allow_set_and_change_raps) => 1 },
                           { Sequel.qualify(:agency_user, :allow_restricted_access) => 1 },
                           { Sequel.qualify(:agency_user, :role) => 'SENIOR_AGENCY_ADMIN' }))
          .order(Sequel.function(:lower, Sequel.qualify(:user, :username)))
          .select(Sequel.qualify(:user, :username),
                  Sequel.qualify(:user, :name),
                  Sequel.qualify(:user, :email),
                  Sequel.qualify(:agency_user, :role),
                  Sequel.qualify(:agency_user, :position),
                  Sequel.qualify(:agency_user, :allow_file_issue),
                  Sequel.qualify(:agency_user, :allow_transfers),
                  Sequel.qualify(:agency_user, :allow_set_and_change_raps),
                  Sequel.qualify(:agency_user, :allow_restricted_access),
                  Sequel.qualify(:agency, :aspace_agency_id))
          .map do |row|
          delegate_by_id[row[:aspace_agency_id]] ||= []
          delegate_by_id[row[:aspace_agency_id]] << {
            'username' => row[:username],
            'name' => row[:name],
            'email' => row[:email],
            'role' => row[:role],
            'position' => row[:position],
            'allow_file_issue' => row[:allow_file_issue] == 1,
            'allow_transfers' => row[:allow_transfers] == 1,
            'allow_set_and_change_raps' => row[:allow_set_and_change_raps] == 1,
            'allow_restricted_access' => row[:allow_restricted_access] == 1,
          }
        end
      end

      delegate_by_id
    end
  end
end