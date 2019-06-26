{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/file_issues",
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
      "issue_type" => {"type" => "string"},

      "urgent" => {"type" => "boolean", "readonly" => "true"},
      "delivery_location" => {"type" => "string", "readonly" => "true"},
      "delivery_address" => {"type" => "string", "readonly" => "true"},
      "delivery_authorizer" => {"type" => "string", "readonly" => "true"},

      "status" => {"type" => "string"},

      "checklist_submitted" => {"type" => "boolean"},
      "checklist_dispatched" => {"type" => "boolean"},
      "checklist_completed" => {"type" => "boolean"},

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
            "id" => {"type" => "integer"},
            "record_details" => {"type" => "string"},
            "dispatch_date" => {"type" => "date"},
            "dispatched_by" => {"type" => "string"},
            "expiry_date" => {"type" => "date"},
            "returned_date" => {"type" => "date"},
            "received_by" => {"type" => "string"},
            "overdue" => {"type" => "boolean", "readonly" => "true"},
            "not_returned" => {"type" => "boolean"},
            "not_returned_note" => {"type" => "string"},
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
