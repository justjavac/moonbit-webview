///|
/// Parses an app config document from JSON text while preserving editable JSON.
pub fn load_app_config_document_from_json(
  text : String,
) -> Result[AppConfigDocument, String] {
  build_app_config_document_from_text(text, None)
}

///|
/// Reads an app config document from disk while preserving editable JSON.
pub fn load_app_config_document_from_file(
  path : String,
) -> Result[AppConfigDocument, String] {
  let config_text : Result[String, _] = try? @mbfs.read_file_to_string(path)
  match config_text {
    Err(error) => Err("failed to read app config: " + error.to_string())
    Ok(text) =>
      build_app_config_document_from_text(text, Some(config_base_dir(path)))
  }
}

///|
fn build_app_config_document_from_text(
  text : String,
  base_dir : String?,
) -> Result[AppConfigDocument, String] {
  let parsed_json : Result[Json, _] = try? @json.parse(text)
  match parsed_json {
    Err(error) => Err("failed to parse app config JSON: " + error.to_string())
    Ok(Object(object)) =>
      build_app_config_document_from_object(object, base_dir)
    Ok(_) => Err("expected object for app config")
  }
}

///|
fn build_app_config_document_from_object(
  object : Map[String, Json],
  base_dir : String?,
) -> Result[AppConfigDocument, String] {
  match build_app_config_from_json(Json::object(object), base_dir) {
    Err(error) => Err(error)
    Ok(config) =>
      match extension_option_entries_from_object(object) {
        Err(error) => Err(error)
        Ok(_) =>
          Ok(AppConfigDocument::{
            raw_object: object,
            base_dir,
            bootstrap_config: config,
          })
      }
  }
}

///|
fn refresh_app_config_document(
  object : Map[String, Json],
  base_dir : String?,
) -> Result[AppConfigDocument, String] {
  build_app_config_document_from_object(object, base_dir)
}

///|
fn extension_option_entries_from_object(
  object : Map[String, Json],
) -> Result[Array[(String, Json)], String] {
  let entries : Array[(String, Json)] = []
  let seen : Map[String, Bool] = {}
  match object.get("extensions") {
    Some(Object(extension_object)) =>
      for name, value in extension_object {
        let normalized = normalize_keyword(name)
        guard normalized != "" else {
          return Err("app config.extensions contains an empty key")
        }
        guard seen.get(name) is None else {
          return Err("duplicate extension options key: " + name)
        }
        guard value is Object(_) else {
          return Err("expected object for app config.extensions." + name)
        }
        seen.set(name, true)
        entries.push((name, clone_json(value)))
      }
    Some(_) => return Err("expected object for app config.extensions")
    None => ()
  }
  Ok(entries)
}
