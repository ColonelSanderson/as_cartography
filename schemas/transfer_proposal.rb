{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/transfer_proposals",
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

      "series" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "title" => {"type" => "string"},
            "disposal_class" => {"type" => "string"},
            "date_range" => {"type" => "string"},
            "accrual_details" => {"type" => "string"},
            "creating_agency" => {"type" => "string"},
            "mandate" => {"type" => "string"},
            "function" => {"type" => "string"},
            "system_of_arrangement" => {"type" => "string"},
            "composition" => {"type" => "array", "items" => {"type" => "string"}},
          }
        }
      },

      "agency_location_display_string" => {"type" => "string"},

      "estimated_quantity" => {"type" => "string"},
      "status" => {"type" => "string"},
    },
  }
}
