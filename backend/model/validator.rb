class Validator

  def initialize
    @validator = MapValidator.new
  end

  def self.validate(path, repo_id)
    new.validate(path, repo_id)
  end

  def validate(path, repo_id)
    errors = []

    @validator.run_validations(path, load_validations(repo_id))
    @validator.notifications.notification_list.each do |notification|
      if notification.source.to_s.empty?
        errors << "#{notification.type} - #{notification.message}"
      else
        errors << "#{notification.type} - [#{notification.source}] #{notification.message}"
      end
    end

    errors
  end


  private

  def load_validations(repo_id)
    validations = @validator.base_validations.clone

    validations[:'Creating Agency'] = lambda {|notifications, meta, col|
      # This field is optional
      return if col.to_s.strip.empty?

      begin
        agency_id = Integer(col)

        if AgentCorporateEntity[agency_id].nil?
          notifications.add_notification(:ERROR, "Creating agency references a non-existent agency: #{agency_id}")
        end
      rescue ArgumentError
        notifications.add_notification(:ERROR, "Creating Agency should contain the QSA ID of an agency (e.g. a number like 123)")
      end
    }

    validations[:'Responsible Agency'] = lambda {|notifications, meta, col|
      if col.to_s.strip.empty?
        notifications.add_notification(:ERROR, "Responsible Agency is required but was missing")
        return
      end

      begin
        agency_id = Integer(col)

        if AgentCorporateEntity[agency_id].nil?
          notifications.add_notification(:ERROR, "Responsible agency references a non-existent agency: #{agency_id}")
        end
      rescue ArgumentError
        notifications.add_notification(:ERROR, "Responsible Agency should contain the QSA ID of an agency (e.g. a number like 123)")
      end
    }

    validations[:'Series ID'] = lambda {|notifications, meta, col|
      if col.to_s.strip.empty?
        notifications.add_notification(:ERROR, "Series ID is required but was missing")
        return
      end

      begin
        series_id = Integer(col)

        if Resource[:id => series_id, :repo_id => repo_id].nil?
          notifications.add_notification(:ERROR, "Series ID references a non-existent series: #{series_id}")
        end
      rescue ArgumentError
        notifications.add_notification(:ERROR, "Series ID must contain the QSA ID of a series (e.g. a number like 123)")
      end
    }

    validations
  end

end
