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

      "status" => {"type" => "string"},

      "representations" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:physical_representation) uri"},
                         {"type" => "JSONModel(:digital_representation) uri"}],
            },
            "id" => {"type" => "integer"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
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
    },
  }
}
