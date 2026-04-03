///|
fn required_string_field(
  object : Map[String, Json],
  key : String,
  label : String,
) -> Result[String, String] {
  match required_field(object, key, label) {
    Err(error) => Err(error)
    Ok(json) => decode_string(json, label)
  }
}

///|
fn required_int_field(
  object : Map[String, Json],
  key : String,
  label : String,
) -> Result[Int, String] {
  match required_field(object, key, label) {
    Err(error) => Err(error)
    Ok(json) => decode_int(json, label)
  }
}

///|
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
fn optional_field(object : Map[String, Json], key : String) -> Json? {
  object.get(key)
}

///|
fn decode_optional_string(
  json : Json?,
  label : String,
) -> Result[String?, String] {
  match json {
    None => Ok(None)
    Some(json) =>
      match decode_string(json, label) {
        Ok(value) => Ok(Some(value))
        Err(error) => Err(error)
      }
  }
}

///|
fn decode_optional_int(json : Json?, label : String) -> Result[Int?, String] {
  match json {
    None => Ok(None)
    Some(json) =>
      match decode_int(json, label) {
        Ok(value) => Ok(Some(value))
        Err(error) => Err(error)
      }
  }
}

///|
fn decode_string(json : Json, label : String) -> Result[String, String] {
  let decoded : Result[String, _] = try? @json.from_json(json)
  match decoded {
    Ok(value) => Ok(value)
    Err(error) => Err("invalid string for " + label + ": " + error.to_string())
  }
}

///|
fn decode_int(json : Json, label : String) -> Result[Int, String] {
  let decoded : Result[Int, _] = try? @json.from_json(json)
  match decoded {
    Ok(value) => Ok(value)
    Err(error) => Err("invalid int for " + label + ": " + error.to_string())
  }
}

///|
fn expect_object(
  json : Json,
  label : String,
) -> Result[Map[String, Json], String] {
  match json {
    Object(object) => Ok(object)
    _ => Err("expected object for " + label)
  }
}
