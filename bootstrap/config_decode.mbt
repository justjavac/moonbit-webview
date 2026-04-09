///|
/// Reads and decodes a required string field from a JSON object.
fn required_string_field(
  object : Map[String, Json],
  key : String,
  label : String,
) -> Result[String, String] {
  required_built_field(object, key, label, fn(json) {
    decode_string(json, label)
  })
}

///|
/// Reads and decodes a required integer field from a JSON object.
fn required_int_field(
  object : Map[String, Json],
  key : String,
  label : String,
) -> Result[Int, String] {
  required_built_field(object, key, label, fn(json) { decode_int(json, label) })
}

///|
/// Returns a required field or a descriptive missing-field error.
fn required_field(
  object : Map[String, Json],
  key : String,
  label : String,
) -> Result[Json, String] {
  match object.get(key) {
    Some(value) => Ok(value)
    None => Err("missing required field: " + label)
  }
}

///|
/// Returns an optional raw JSON field from an object.
fn optional_field(object : Map[String, Json], key : String) -> Json? {
  object.get(key)
}

///|
/// Decodes an optional string field while preserving `None`.
fn decode_optional_string(
  json : Json?,
  label : String,
) -> Result[String?, String] {
  match json {
    None => Ok(None)
    Some(json) => decode_string(json, label).map(fn(value) { Some(value) })
  }
}

///|
/// Decodes an optional integer field while preserving `None`.
fn decode_optional_int(json : Json?, label : String) -> Result[Int?, String] {
  match json {
    None => Ok(None)
    Some(json) => decode_int(json, label).map(fn(value) { Some(value) })
  }
}

///|
/// Decodes a JSON value as a string with a labeled error message.
fn decode_string(json : Json, label : String) -> Result[String, String] {
  let decoded : Result[String, _] = try? @json.from_json(json)
  match decoded {
    Ok(value) => Ok(value)
    Err(error) => Err("invalid string for " + label + ": " + error.to_string())
  }
}

///|
/// Decodes a JSON value as an integer with a labeled error message.
fn decode_int(json : Json, label : String) -> Result[Int, String] {
  let decoded : Result[Int, _] = try? @json.from_json(json)
  match decoded {
    Ok(value) => Ok(value)
    Err(error) => Err("invalid int for " + label + ": " + error.to_string())
  }
}

///|
/// Ensures a JSON value is an object before continuing config decoding.
fn expect_object(
  json : Json,
  label : String,
) -> Result[Map[String, Json], String] {
  match json {
    Object(object) => Ok(object)
    _ => Err("expected object for " + label)
  }
}
