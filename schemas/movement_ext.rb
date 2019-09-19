{
  "move_context" => {
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
        "type" => [{"type" => "JSONModel(:file_issue) uri"},
                   {"type" => "JSONModel(:transfer) uri"},
                   {"type" => "JSONModel(:assessment) uri"},
                   {"type" => "JSONModel(:batch_action) uri"}],
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
