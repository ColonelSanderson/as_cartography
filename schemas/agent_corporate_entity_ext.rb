{
  "delegates" => {
    "type" => "array",
    "readonly" => "true",
    "items" => {
      "type" => "object",
      "properties" => {
        "username" => {"type" => "string"},
        "name" => {"type" => "string"},
        "email" => {"type" => "string"},
        "role" => {"type" => "string"},
        "position" => {"type" => "position"},
        "allow_file_issue" => {"type" => "boolean"},
        "allow_transfers" => {"type" => "boolean"},
        "allow_set_and_change_rap" => {"type" => "boolean"},
        "allow_restricted_access" => {"type" => "boolean"},
      }
    }
  }
}