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
     :disposal_class,
     :title,
     :description,
     :agency_control_number,
     :sequence,
     :sequence_ref,
     :attachment_notes,
     :restricted_access_period,
     :publish,
     :start_date,
     :end_date,
     :representation_type,
     :format,
     :contained_within,
     :box_number,
     :remarks,
     :series,
     :responsible_agency,
     :creating_agency,
     :sensitivity_label,
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
        :description => "Agency Transfer CSV"
      }
    ]
  end


  def self.profile
    "Convert an Agency Transfer CSV to ArchivesSpace records"
  end


  def initialize(input_file, opts = {})
    super
    @batch = ASpaceImport::RecordBatch.new
    @input_file = input_file
    @records = []

    @items = []
    @representations = []

    @transfer_uri = opts['transfer_uri'] or raise "No Transfer URI!!"

    @series_uris = {}
    @agency_uris = {}
  end


  def run
    rows = CSV.read(@input_file)

    # drop column headers
    rows.shift

    begin
      while(row = rows.shift)
        values = row_values(row)

        next if values.compact.empty?

        values_map = Hash[@@columns.zip(values)]

        if values_map[:sequence_ref]
          # a representation
          @representations << values_map
        else
          # an item
          @items << values_map
        end
      end

      @items.each do |item|
        @records << format_item(item)
      end

      raise "Unlinked representations!!" unless @representations.empty?

    rescue StopIteration
    end

    # assign all records to the batch importer in reverse
    # order to retain position from spreadsheet
    @records.reverse.each{|record| @batch << record}
  end


  def get_output_path
    output_path = @batch.get_output_path

    p "=================="
    p output_path
    p File.read(output_path)
    p "=================="

    output_path
  end


  private

  def row_values(row)
    (0...row.size).map {|i| row[i] ? row[i].to_s.strip : ''}
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
      :resource => {
        :ref => series_uri_for(item[:series_id])
      },
      :sensitivity_label => format_sensitivity_label(item[:sensitivity_label]),
      :physical_representations => [],
      :digital_representations => [],
      :series_system_agent_relationships => [],
      :series_system_transfer_relationships => [
        {
          :start_date => item[:start_date],
          :jsonmodel_type => 'series_system_transfer_record_containment_relationship',
          :relator => 'is_contained_within',
          :ref => @transfer_uri,
        }
      ]
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
        :format => rep[:format],
        :contained_within => rep[:contained_within],
      }

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

    item_hash
  end

end
