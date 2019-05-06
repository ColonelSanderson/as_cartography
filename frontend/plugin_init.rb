ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

Rails.application.config.after_initialize do
  # Eager load
  JSONModel(:transfer)
  JSONModel(:transfer_proposal)
end
