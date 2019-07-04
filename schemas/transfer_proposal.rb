{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/transfer_proposals",
    "properties" => {
      "uri" => {"type" => "string"},

      "title" => {"type" => "string"},
      "description" => {"type" => "string"},

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

      "series" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "title" => {"type" => "string"},
            "description" => {"type" => "string"},
            "disposal_class" => {"type" => "string"},
            "date_range" => {"type" => "string"},
            "accrual" => {"type" => "boolean"},
            "accrual_details" => {"type" => "string"},
            "creating_agency" => {"type" => "string"},
            "mandate" => {"type" => "string"},
            "function" => {"type" => "string"},
            "system_of_arrangement" => {"type" => "string"},
            "composition" => {"type" => "array", "items" => {"type" => "string"}},
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

      "estimated_quantity" => {"type" => "string"},
      "status" => {"type" => "string"},

      "handle_id" => {"type" => "string", "readonly" => "true"},

      "transfer" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:transfer) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "identifier" => {"type" => "string", "readonly" => "true"},
      "display_string" => {"type" => "string", "readonly" => "true"},

      "lodged_by" => {"type" => "string"},
    },
  }
}
