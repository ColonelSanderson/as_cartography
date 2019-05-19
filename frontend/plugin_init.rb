ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  # Eager load all JSON schemas
  Dir.glob(File.join(File.dirname(__FILE__), "..", "schemas", "*.rb")).each do |schema|
    JSONModel(File.basename(schema, ".rb").intern)
  end
end
