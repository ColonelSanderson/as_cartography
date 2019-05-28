{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/file_issue",
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

      "agency_location_display_string" => {"type" => "string"},
      "handle_id" => {"type" => "string", "readonly" => "true"},
      "request_type" => {"type" => "string"},
      "urgent" => {"type" => "boolean", "readonly" => "true"},
      "deliver_to_reading_room" => {"type" => "boolean", "readonly" => "true"},
      "delivery_authorizer" => {"type" => "string", "readonly" => "true"},
      "status" => {"type" => "string"},

      "requested_representations" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:physical_representation) uri"},
                         {"type" => "JSONModel(:digital_representation) uri"}],
            },
            "request_type" => {"type" => "string"},
            "record_details" => {"type" => "string"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "file_issue_request" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:file_issue_request) uri"}],
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
