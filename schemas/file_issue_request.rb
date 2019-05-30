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
      "delivery_location" => {"type" => "string", "readonly" => "true"},
      "delivery_authorizer" => {"type" => "string", "readonly" => "true"},
      "physical_request_status" => {"type" => "string"},
      "digital_request_status" => {"type" => "string"},
      "digital_processing_estimate" => {"type" => "string"},
      "physical_processing_estimate" => {"type" => "string"},
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

      "file_issue_physical" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:file_issue) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "file_issue_digital" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:file_issue) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "version" => {"type" => "integer"},
      "digital_quote_for_version" => {"type" => "integer"},
      "physical_quote_for_version" => {"type" => "integer"},
    },
  }
}
