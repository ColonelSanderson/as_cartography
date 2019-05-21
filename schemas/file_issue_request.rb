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
      "delivery_authorizer" => {"type" => "string", "readonly" => "true"},
      "physical_request_status" => {"type" => "string"},
      "digital_request_status" => {"type" => "string"},
      "request_notes" => {"type" => "string", "readonly" => "true"},

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

      "physical_quote" => {
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

      "digital_quote" => {
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
