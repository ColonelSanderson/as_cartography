require 'date'
require 'time'

class AgencyTransferConverter < Converter

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
  #   attachment_notes          Audio tape                     NOT IMPORTED - IGNORE
  #   restricted_access_period  75                             representation.access_category
  #   publish                   No                             NOT IMPORTED - IGNORE
  #   start_date                2018-10-01                     archival_object.dates.begin
  #   end_date                  2019-01-01                     archival_object.dates.end
  #   representation_type       Physical                       physical_representation or digital_representation
  #   format                    Magnetic Media, Cassette Tape  representation.format
  #   contained_within          Physical - Other               representation.contained_within
  #   box_number                5                              NOT IMPORTED - IGNORE
  #   remarks                                                  NOT IMPORTED - IGNORE
  #   series                    123                            resource.qsa_id
  #   responsible_agency        456                            agent_corporate_entity.qsa_id control
  #   creating_agency           789                            agent_corporate_entity.qsa_id creation
  #   sensitivity_label         Cultural Sensitivity Warning   archival_object.user_defined.user_defined_enum_2


  @@columns =
    [
     {:label => "Disposal Class", :key => :disposal_class},
     {:label => "Title", :key => :title},
     {:label => "Description", :key => :description},
     {:label => "Agency Control number", :key => :agency_control_number},
     {:label => "Sequence Number", :key => :sequence},
     {:label => "Attachment Related to Sequence Number", :key => :sequence_ref},
     {:label => "Attachment Notes", :key => :attachment_notes},
     {:label => "Restricted Access Period", :key => :restricted_access_period},
     {:label => "Publish Metadata?", :key => :publish},
     {:label => "Start Date (DD/MM/YYYY)", :type => :date, :key => :start_date},
     {:label => "End Date (DD/MM/YYYY)", :type => :date, :key => :end_date},
     {:label => "Representation Type", :key => :representation_type},
     {:label => "Format", :key => :format},
     {:label => "Contained within", :key => :contained_within},
     {:label => "Box Number", :key => :box_number},
     {:label => "Remarks", :key => :remarks},
     {:label => "Series ID", :key => :series},
     {:label => "Responsible Agency", :key => :responsible_agency},
     {:label => "Creating Agency", :key => :creating_agency},
     {:label => "Sensititvity Label", :key => :sensitivity_label},
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

    @transfer_id = opts[:transfer_id] or raise "No Transfer ID!!"

    @series_uris = {}
    @agency_uris = {}
  end


  def run
    ordered_column_keys = []

    XLSXStreamingReader.new(@input_file).each.each_with_index do |row, idx|
      if idx == 0
        # Our header row.  Map this back to our column definitions.
        ordered_column_keys = row.map do |r|
          column = @@columns.find {|c| c[:label] == r.strip}

          if column
            column[:key]
          else
            raise "Unrecognised column: #{r.strip}"
          end
        end

        next
      end

      values = row_values(row)

      next if values.select{|v| !v.empty?}.compact.empty?

      values_map = Hash[ordered_column_keys.zip(values)]

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

    raise "Unlinked representations!!" unless @representations.empty?


    # assign all records to the batch importer in reverse
    # order to retain position from spreadsheet
    @records.reverse.each{|record| @batch << record}
  end


  def get_output_path
    @batch.get_output_path
  end


  private

  def row_values(row)
    # We want a value for every column, even if that value is an empty string.
    # Our row might be shorter than the total number of columns possible.
    (0...@@columns.size).map {|i|
      column_definition = @@columns[i]

      if row[i].is_a?(Time)
        row[i].to_date.iso8601
      elsif column_definition[:type] == :date && !row[i].to_s.empty?
        # If we have a date string in DD/MM/YYYY, accept that too
        Date.strptime(row[i].to_s, '%d/%m/%Y').iso8601
      else
        row[i].to_s.strip
      end
    }
  end


  def series_uri_for(id)
    @series_uris[id] ||= (Resource[:qsa_id => id] or raise "No Series for #{id}!!").uri
  end


  def agency_uri_for(id)
    @agency_uris[id] ||= (AgentCorporateEntity[:qsa_id => id] or raise "No Agency for #{id}!!").uri
  end


  def format_sensitivity_label(label)
    # FIXME: might have to map back to enum value from translation ... sigh
    label
  end


  def mint_fresh_container(transfer_id)
    @minty_fresh ||= TopContainer.create_from_json(JSONModel::JSONModel(:top_container).from_hash(
                                                     'barcode' => "#{transfer_id}_#{SecureRandom.hex}",
                                                     'indicator' => transfer_id,
                                                     'type' => 'box',
                                                     'current_location' => 'HOME',
                                                   ))
  end

  def format_item(item)
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
                   :end => item[:end_date],
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

    # grab this item's representations
    reps = @representations.select{|rep| rep[:sequence_ref] == item[:sequence]}
    # and drop them ... must be a nice way to do this in one pass
    @representations.delete_if{|rep| rep[:sequence_ref] == item[:sequence]}

    # also add the item itself as a representation
    reps.unshift(item)

    reps.each do |rep|
      rep_key = rep[:representation_type].downcase.start_with?('p') ? :physical_representations : :digital_representations

      rep_hash = {
        :title => rep[:title].empty? ? item[:title] : rep[:title],
        :access_category => rep[:restricted_access_period],
        :format => rep[:format].empty? ? item[:format] : rep[:format],
        :contained_within => rep[:contained_within],
        :current_location => 'TFR',
        :normal_location => 'TFR',
        :agency_assigned_id => rep[:agency_control_number],
      }

      if rep_key == :physical_representations
        # THINKME: Need a top container.  Spam one in there for now.
        rep_hash['container'] = {'ref' => mint_fresh_container(@transfer_id.to_s).uri}
      end

      item_hash[rep_key] << rep_hash
    end

    unless item[:responsible_agency].empty?
      item_hash[:series_system_agent_relationships] << {
        :start_date => item[:start_date],
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :ref => agency_uri_for(item[:responsible_agency]),
      }
    end

    unless item[:creating_agency].empty?
      item_hash[:series_system_agent_relationships] << {
        :start_date => item[:start_date],
        :jsonmodel_type => 'series_system_agent_record_creation_relationship',
        :relator => 'established_by',
        :ref => agency_uri_for(item[:creating_agency]),
      }
    end

    JSONModel::JSONModel(:archival_object).from_hash(item_hash)
  end

end
