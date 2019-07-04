{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/search_requests",
    "properties" => {
      "uri" => {"type" => "string"},

      "identifier" => {"type" => "string", "readonly" => "true"},
      "display_string" => {"type" => "string", "readonly" => "true"},

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

      "agency_location_display_string" => {"type" => "string"},
      "handle_id" => {"type" => "string", "readonly" => "true"},

      "details" => {"type" => "string"},

      "date_details" => {"type" => "string"},

      "purpose" => {"type" => "string"},

      "status" => {"type" => "string"},

      "draft" => {"type" => "boolean", "readonly" => "true"},

      "files" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "key" => {"type" => "string"},
            "filename" => {"type" => "string"},
            "mime_type" => {"type" => "string"},
          }
        }
      },

      "quote" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:service_quote) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "lodged_by" => {"type" => "string"},
    },
  }
}
