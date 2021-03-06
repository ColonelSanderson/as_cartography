require 'date'
require 'time'

class AgencyTransferConverter < Converter

  class TransferImportException < StandardError; end

  # Each row is a representation, physical or digital
  # It either includes or references an item
  # Its item references an existing series, and links to agencies
  #
  #   COLUMN                    SAMPLE CONTENT                 MAPPING GUESS
  #   ======                    ==============                 =============
  #
  #   disposal_class            QDAN705v1/2.1.1                NEW FIELD on archival_object.disposal_class
  #   title                     Hearing Notes                  archival_object.title or representation.title
  #   description                                              archival_object.description
  #   agency_control_number     90/5489/1                      archival_object.agency_assigned_id
  #   sequence                  4                              internal ref
  #   sequence_ref              3                              pointer to internal ref linking rep to ao
  #   access_category           All public records             rap_attached.access_category
  #   restricted_access_period  75                             rap_attached.years
  #   publish                   N                              rap_attached.open_access_metadata
  #   start_date                2018-10-01                     archival_object.dates.begin
  #   start_date_qualifier      Approximate                    archival_object.dates.certainty
  #   end_date                  2019-01-01                     archival_object.dates.end
  #   end_date_qualifier                                       archival_object.dates.certainty_end
  #   representation_type       Physical                       physical_representation or digital_representation
  #   format                    Magnetic Media, Cassette Tape  representation.format
  #   contained_within          Physical - Other               representation.contained_within
  #   box_number                5                              create top_containers with indicator: SID-TID-B{box-number}
  #   remarks                                                  NOT IMPORTED - IGNORE
  #   series                    123                            resource.qsa_id
  #   responsible_agency        456                            agent_corporate_entity.qsa_id control
  #   creating_agency           789                            agent_corporate_entity.qsa_id creation
  #   sensitivity_label         Cultural Sensitivity Warning   archival_object.user_defined.user_defined_enum_2

  # The latest, 'final', round of changes from piv##169243505
  #
  #  Done
  #   - map description to reps as well as aos
  #   - fix handling of dates prior to 1900
  #   - include transfer qsa_id on token in ao ... did transfer_proposal in transfer too
  #   - support incomplete dates
  #   - ensure boxes from different series are rendered as separate boxes
  #   - set container location to HOME not SORTRM
  #   - show transfers summary on series (highly desirable)
  #
  #  No action required: handle in validation
  #   - publish details defaults to inherit - AWAITING CLARIFICATION
  #
  # Validation changes
  #   - sync up enum validation with vocabs in spreadsheet - sigh
  #   - validate pre-1900 dates
  #   - validate incomplete dates
  #   - validate title Map+AS
  #   - validate box number AS
  #   - validate start and end date on items only - MAP+AS
  #   - validate representation type MAP+AS
  #   - validate format MAP+AS
  #   - validate contained within MAP+AS
  #   - validate series id AS
  #   - ensure :restricted_access_period and :publish are empty if :access_category is empty

  @@columns =
    [
     {:label => "Disposal Class", :key => :disposal_class},
     {:label => "Title", :key => :title},
     {:label => "Description", :key => :description},
     {:label => "Sequence Number", :key => :sequence},
     {:label => "Attachment Related to Sequence Number", :key => :sequence_ref},
     {:label => "Agency Control number", :key => :agency_control_number},
     {:label => "Box Number", :key => :box_number},
     {:label => "Publish Details?", :key => :publish},
     {:label => "Start Date (DD/MM/YYYY)", :type => :date, :key => :start_date},
     {:label => "Start Date Qualifier", :key => :start_date_qualifier},
     {:label => "End Date (DD/MM/YYYY)", :type => :date, :key => :end_date},
     {:label => "End Date Qualifier", :key => :end_date_qualifier},
     {:label => "Access Category", :key => :access_category},
     {:label => "Restricted Access Period", :key => :restricted_access_period},
     {:label => "Representation Type", :key => :representation_type},
     {:label => "Format", :key => :format},
     {:label => "Contained within", :key => :contained_within},
     {:label => "Series ID", :key => :series},
     {:label => "Responsible Agency", :key => :responsible_agency},
     {:label => "Creating Agency", :key => :creating_agency},
     {:label => "Sensitivity Label", :key => :sensitivity_label},
     {:label => "Remarks", :key => :remarks},
    ]

  def self.instance_for(type, input_file, opts = {})
    if type == "agency_transfer"
      self.new(input_file, opts)
    else
      nil
    end
  end


  def self.import_types(show_hidden = false)
    [
      {
        :name => "agency_transfer",
        :description => "Agency Transfer Import"
      }
    ]
  end


  def self.profile
    "Convert an Agency Transfer Import to ArchivesSpace records"
  end


  def initialize(input_file, opts = {})
    super
    @batch = ASpaceImport::RecordBatch.new
    @input_file = input_file
    @records = []

    # let's not be special, opt keys might come in as strings or symbols - woteva
    opts = opts.map{|k,v| [k.intern, v]}.to_h

    @items = []
    @representations = []

    @transfer_id = opts[:transfer_id] or handle_error("No Transfer ID provided.")

    @series_uris = {}
    @agency_uris = {}

    @current_row = 0
  end


  def run
    ordered_column_keys = []

    XLSXStreamingReader.new(@input_file).each.each_with_index do |row, idx|
      if idx == 0
        # Our header row.  Map this back to our column definitions.
        ordered_column_keys = row.compact.map do |r|
          column = @@columns.find {|c| c[:label] == r.strip}

          if column
            column[:key]
          else
            handle_error(bad_column_label_error(r.strip))
          end
        end

        next
      end

      values = row_values(row)

      next if values.select{|v| !v.empty?}.compact.empty?

      values_map = Hash[ordered_column_keys.zip(values)].merge(:ROW_INDEX => idx + 1)


      if values_map[:sequence_ref].empty? && values_map[:sequence].empty?
        @current_row = idx + 1
        handle_error(unattached_row_error(values_map[:title]))
      end

      if values_map[:sequence_ref].empty?
        # an item
        @items << values_map
      else
        # a representation
        @representations << values_map
      end
    end

    @items.each do |item|
      @records << format_item(item)
    end

    handle_error(unlinked_representations_error(@representations)) unless @representations.empty?


    # assign all records to the batch importer in reverse
    # order to retain position from spreadsheet
    @records.reverse.each{|record| @batch << record}
  end


  def get_output_path
    @batch.get_output_path
  end


  private


  def handle_error(msg, col = false)
    message = "\n\n  #{msg}\n    At: "
    message += "column [#{column_label_for(col)}], " if col
    message += "row #{@current_row}\n\n"

    raise TransferImportException.new(message)
  end


  def column_label_for(key)
    (@@columns.select{|c| c[:key] == key}.first || {})[:label]
  end


  def row_values(row)
    # We want a value for every column, even if that value is an empty string.
    # Our row might be shorter than the total number of columns possible.
    (0...@@columns.size).map {|i|
      column_definition = @@columns[i]

      if row[i].is_a?(Time)
        row[i].to_date.iso8601
      elsif column_definition[:type] == :date && !row[i].to_s.empty?
        # If we have a date string in DD/MM/YYYY, accept that too
        # ... and now MM/YYYY and YYYY as well - fun times
        row[i].to_s.split(/\D+/).reverse.join('-')
      else
        row[i].to_s.strip
      end
    }
  end


  def series_uri_for(id)
    @series_uris[id] ||= (Resource[:qsa_id => id] or handle_error("No Series record found for id #{id}", :series)).uri
  end


  def agency_uri_for(id, col = nil)
    @agency_uris[id] ||= (AgentCorporateEntity[:qsa_id => id] or handle_error("No Agency record found for id #{id}", col)).uri
  end


  def format_sensitivity_label(label)
    # FIXME: might have to map back to enum value from translation ... sigh
    label
  end


  def format_rap_attached(row)
    {
      'open_access_metadata' => row[:publish] == 'Y' ? true : false,
      'years' => row[:restricted_access_period],
      'internal_reference' => "ARK Reference",
      'access_status' => "Restricted Access",
      'access_category' => row[:access_category],
    }
  end


  def current_user_agent
    @user_agent ||= User.to_jsonmodel(User.find(:username => Thread.current[:request_context][:current_username]))['agent_record']
  end


  def container_for(series, transfer, box_number)
    @containers ||= {}

    # Box number is required. Unboxed items will be given a unique
    # box number manually by transfer staff
    handle_error("No Box Number provided", :box_number) unless box_number

    box = box_number.to_s

    indicator = "S#{series}-T#{transfer}-B#{box}"

    return @containers[indicator] if @containers[indicator]

    hash = {
      'indicator' => indicator,
      'type' => 'box',
      'current_location' => 'HOME',
      'movements' =>
      [
         {
           'user' => current_user_agent,
           'move_date' => Time.now.getlocal.iso8601,
           'functional_location' => 'HOME',
           'move_context' => {'ref' => "/transfers/#{transfer}"}
         }
      ]
    }

    @containers[indicator] = TopContainer.create_from_json(JSONModel::JSONModel(:top_container).from_hash(hash))
  end


  def format_item(item)
    @current_row = item[:ROW_INDEX]
    item_hash = {
      :uri => "/repositories/12345/archival_objects/import_#{SecureRandom.hex}",
      :disposal_class => item[:disposal_class],
      :title => item[:title],
      :description => item[:description],
      :agency_assigned_id => item[:agency_control_number],
      :level => 'item',
      :dates => [
                 {
                   :begin => item[:start_date],
                   :certainty => (item[:start_date_qualifier] && item[:start_date_qualifier].downcase),
                   :end => item[:end_date],
                   :certainty_end => (item[:end_date_qualifier] && item[:end_date_qualifier].downcase),
                   :label => 'existence',
                   :date_type => 'inclusive',
                 }
                ],
      :resource => { :ref => series_uri_for(item[:series]) },
      :transfer => { :ref => "/transfers/#{@transfer_id}" },
      :sensitivity_label => format_sensitivity_label(item[:sensitivity_label]),
      :physical_representations => [],
      :digital_representations => [],
      :series_system_agent_relationships => [],
    }

    unless item[:access_category].empty?
      item_hash[:rap_attached] = format_rap_attached(item)
    end

    # grab this item's representations
    reps = @representations.select{|rep| rep[:sequence_ref] == item[:sequence]}
    # and drop them ... must be a nice way to do this in one pass
    @representations.delete_if{|rep| rep[:sequence_ref] == item[:sequence]}

    # also add the item itself as a representation
    reps.unshift(item)

    reps.each do |rep|
      @current_row = rep[:ROW_INDEX]
      rep_key = rep[:representation_type].downcase.start_with?('p') ? :physical_representations : :digital_representations

      rep_hash = {
        :title => rep[:title].empty? ? item[:title] : rep[:title],
        :description => rep[:description].empty? ? item[:description] : rep[:description],
        :format => rep[:format].empty? ? item[:format] : rep[:format],
        :contained_within => rep[:contained_within],
        :current_location => 'HOME',
        :normal_location => 'HOME',
        :agency_assigned_id => rep[:agency_control_number],
      }

      # attach a rap only if we have rap data and this is not an item row
      if !rep[:access_category].empty? && !rep[:sequence_ref].empty?
        rep_hash[:rap_attached] = format_rap_attached(rep)
      end

      if rep_key == :physical_representations
        rep_hash['container'] = {'ref' => container_for(item[:series], @transfer_id, rep[:box_number]).uri}

        rep_hash['movements'] =
          [
           {
             'user' => current_user_agent,
             'move_date' => Time.now.getlocal.iso8601,
             'functional_location' => 'HOME',
             'move_context' => {'ref' => "/transfers/#{@transfer_id}"}
           }
          ]
      end

      item_hash[rep_key] << rep_hash
    end

    unless item[:responsible_agency].empty?
      item_hash[:series_system_agent_relationships] << {
        :start_date => item[:start_date],
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :ref => agency_uri_for(item[:responsible_agency], :responsible_agency),
      }
    end

    unless item[:creating_agency].empty?
      item_hash[:series_system_agent_relationships] << {
        :start_date => item[:start_date],
        :jsonmodel_type => 'series_system_agent_record_creation_relationship',
        :relator => 'established_by',
        :ref => agency_uri_for(item[:creating_agency], :creating_agency),
      }
    end

    JSONModel::JSONModel(:archival_object).from_hash(item_hash)
  end


  def unattached_row_error(title)
    <<~EOT
      Unattached row:
          #{title}

          If a row has no value in column:
            [#{column_label_for(:sequence_ref)}]
          Then it must have a value in column:
            [#{column_label_for(:sequence)}]
    EOT
  end


  def unlinked_representations_error(reps)
    <<~EOT
      #{reps.length} unattached row#{reps.length == 1 ? '' : 's'}.

            #{reps.map{|r| 'Row %d: %s' % [r[:ROW_INDEX], r[:title]]}.join("\n      ")}
    EOT
  end


  def bad_column_label_error(label)
    <<~EOT
      Unrecognised column heading: [#{label}]

          The following columns are supported:
            #{@@columns.map{|c| c[:label]}.join("\n      ")}
    EOT
  end
end
