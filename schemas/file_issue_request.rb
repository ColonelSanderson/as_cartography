{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/file_issue_requests",
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
      "delivery_authorizer" => {"type" => "text", "readonly" => "true"},
      "status" => {"type" => "text"},
      "request_notes" => {"type" => "text", "readonly" => "true"},

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
          }
        }
      },

      # Not sure how these will look yet.
      # "active_quote" => {},
      # "previous_quotes" => {},

      # FIXME: We'll ultimately need one of these
      # "file_issue" => {
      #   "readonly" => "true",
      #   "type" => "object",
      #   "subtype" => "ref",
      #   "properties" => {
      #     "ref" => {
      #       "type" => [{"type" => "JSONModel(:file_issue) uri"}],
      #     },
      #     "_resolved" => {
      #       "type" => "object",
      #       "readonly" => "true"
      #     }
      #   }
      # },
    },
  }
}
