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
            "role" => {"type" => "string", "dynamic_enum" => "transfer_file_role"},
            "mime_type" => {"type" => "string"},
          }
        }
      },

      "agency_location_display_string" => {"type" => "string"},

      "status" => {"type" => "string"},

      "checklist_transfer_proposal_approved" => {"type" => "boolean"},
      "checklist_metadata_received" => {"type" => "boolean"},
      "checklist_rap_received" => {"type" => "boolean"},
      "checklist_metadata_approved" => {"type" => "boolean"},
      "checklist_transfer_received" => {"type" => "boolean"},
      "checklist_metadata_imported" => {"type" => "boolean"},

      "handle_id" => {"type" => "string", "readonly" => "true"},

      "date_scheduled" => {"type" => "string"},
      "date_received" => {"type" => "string"},
      "quantity_received" => {"type" => "string"},

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

      "import_job" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:job) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "identifier" => {"type" => "string", "readonly" => "true"},
      "display_string" => {"type" => "string", "readonly" => "true"},
    },
  }
}
