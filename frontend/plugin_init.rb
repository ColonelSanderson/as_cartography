ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  Plugins.add_facet_group_i18n("controlling_record_u_sstr",
                               proc {|facet| "search_results.controlling_record.current" })

  # Eager load all JSON schemas
  Dir.glob(File.join(File.dirname(__FILE__), "..", "schemas", "*.rb")).each do |schema|
    JSONModel(File.basename(schema, ".rb").intern)
  end
end
