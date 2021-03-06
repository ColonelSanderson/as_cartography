{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/agency_reading_room_requests",
    "properties" => {
      "uri" => {"type" => "string"},

      "title" => {"type" => "string", "readonly" => "true"},

      "item_id" => {"type" => "string"},
      "item_uri" => {"type" => "string"},
      "status" => {"type" => "string"},
      "date_required" => {"type" => "integer"},
      "time_required" => {"type" => "string"},

      "requested_item" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => "JSONModel(:physical_representation) uri",
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "requesting_agency" => {
        "readonly" => "true",
        "type" => "object",
        "subtype" => "ref",
        "readonly" => "true",
        "properties" => {
          "location_name" => {"type" => "string"},
          "ref" => {
            "type" => "JSONModel(:agent_corporate_entity) uri",
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "handle_id" => {"type" => "string", "readonly" => "true"},

      "created_by" => {"type" => "string"},
      "modified_by" => {"type" => "string"},
      "create_time" => {"type" => "integer"},
      "modified_time" => {"type" => "integer"},
    }
  }
}
