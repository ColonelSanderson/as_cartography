class Validator

  def initialize
    @validator = MapValidator.new(BackendEnumSource)
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

    validations[:'Publish Details?'] = lambda {|notifications, meta, col|
      if col.to_s.strip.empty?
        if meta[:row_fields][meta[:headers].index("Access Category")].to_s.strip.empty?
          # OK: both empty
        else
          notifications.add_notification(:ERROR, "Publish Details? must be provided when Access Category is set",
                                         @validator.formatSource(meta))
        end
      else
        @validator.is_boolean(notifications, meta.merge(mandatory: true, true_value: 'Y', false_value: 'N'), col)
      end
    }

    validations[:'Access Category'] = lambda {|notifications, meta, col|
      if col.to_s.strip.empty?
        if meta[:row_fields][meta[:headers].index("Publish Details?")].to_s.strip.empty?
          # OK: both empty
        else
          notifications.add_notification(:ERROR, "Access Category must be provided when Publish Details? is set",
                                         @validator.formatSource(meta))
        end
      else
        @validator.is_in_vocab(notifications, meta.merge(vocabulary: @validator.enum_source.values_for('runcorn_rap_access_category')), col)
      end
    }


    validations[:'Creating Agency'] = lambda {|notifications, meta, col|
      # This field is optional
      return if col.to_s.strip.empty?

      begin
        agency_id = Integer(col)

        if AgentCorporateEntity[agency_id].nil?
          notifications.add_notification(:ERROR, "Creating agency references a non-existent agency: #{agency_id}",
                                         @validator.formatSource(meta))
        end
      rescue ArgumentError
        notifications.add_notification(:ERROR, "Creating Agency should contain the QSA ID of an agency (e.g. a number like 123)",
                                       @validator.formatSource(meta))
      end
    }

    validations[:'Responsible Agency'] = lambda {|notifications, meta, col|
      if meta[:row_fields][meta[:headers].index("Sequence Number")].to_s.empty?
        # Representation
        unless col.to_s.strip.empty?
          notifications.add_notification(:ERROR, "Representation cannot have a responsible agency",
                                         @validator.formatSource(meta))
        end

        return
      end

      # This is an item record and it is optional
      return if col.to_s.strip.empty?

      begin
        agency_id = Integer(col)

        if AgentCorporateEntity[agency_id].nil?
          notifications.add_notification(:ERROR, "Responsible agency references a non-existent agency: #{agency_id}",
                                         @validator.formatSource(meta))
        end
      rescue ArgumentError, TypeError
        notifications.add_notification(:ERROR, "Responsible Agency should contain the QSA ID of an agency (e.g. a number like 123)",
                                       @validator.formatSource(meta))
      end
    }

    validations[:'Series ID'] = lambda {|notifications, meta, col|
      # series id is not required on attachment rows
      is_attachment = !!meta[:row_fields][meta[:headers].index("Attachment Related to Sequence Number")]

      if is_attachment
        return
      else
        if col.to_s.strip.empty?
          notifications.add_notification(:ERROR, "Series ID is required but was missing", @validator.formatSource(meta))
          return
        end
      end

      begin
        series_id = Integer(col)

        if Resource[:id => series_id, :repo_id => repo_id].nil?
          notifications.add_notification(:ERROR, "Series ID references a non-existent series: #{series_id}",
                                         @validator.formatSource(meta))
        end
      rescue ArgumentError
        notifications.add_notification(:ERROR, "Series ID must contain the QSA ID of a series (e.g. a number like 123)",
                                       @validator.formatSource(meta))
      end
    }

    validations
  end

end
