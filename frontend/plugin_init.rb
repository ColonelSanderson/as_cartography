ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  Plugins.add_facet_group_i18n("controlling_record_u_sstr",
                               proc {|facet| "search_results.controlling_record.current" })

  # Eager load all JSON schemas
  Dir.glob(File.join(File.dirname(__FILE__), "..", "schemas", "*.rb")).each do |schema|
    next if schema.end_with?('_ext.rb')
    JSONModel(File.basename(schema, ".rb").intern)
  end

  Plugins.register_plugin_section(
    Plugins::PluginReadonlySearch.new(
      'as_cartography',
      'file_issues',
      ['physical_representation', 'digital_representation'],
      {
        filter_term_proc: proc { |record| { "file_issue_item_uri_u_sstr" => record.uri }.to_json },
        heading_text: I18n.t("file_issue._plural"),
        sidebar_label: "N/A",
      }
    )
  )
end
