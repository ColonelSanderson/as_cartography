{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/transfers",
    "properties" => {
      "uri" => {"type" => "string"},

      "title" => {"type" => "string"},

      "agency" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "files" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "key" => {"type" => "string"},
            "filename" => {"type" => "string"},
            "role" => {"type" => "string"},
            "mime_type" => {"type" => "string"},
          }
        }
      },

      "agency_location_display_string" => {"type" => "string"},

      "status" => {"type" => "string"},

      "handle_id" => {"type" => "string", "readonly" => "true"},

      "transfer_proposal" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:transfer_proposal) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
    },
  }
}
