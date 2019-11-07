{
  "transfers" => {
    "type" => "array",
    "readonly" => "true",
    "items" => {
      "type" => "object",
      "subtype" => "ref",
      "properties" => {
        "ref" => {
          "type" => [{"type" => "JSONModel(:transfer) uri"}],
          "readonly" => "true"
        },
        "_resolved" => {
          "type" => "object",
          "readonly" => "true"
        }
      }
    }
  }
}
