///|
/// Parses an app manifest document from JSON text while preserving editable JSON.
/// The returned document keeps both the normalized manifest view and the raw
/// JSON structure needed for future manifest edits.
pub fn load_app_manifest_document_from_json(
  text : String,
) -> Result[AppManifestDocument, String] {
  build_app_manifest_document_from_text(text, None)
}

///|
/// Reads an app manifest document from disk while preserving editable JSON.
/// The document remembers the manifest file's parent directory so later file
/// entries and extension contexts can resolve relative paths consistently.
pub fn load_app_manifest_document_from_file(
  path : String,
) -> Result[AppManifestDocument, String] {
  read_app_manifest_text(path).bind(fn(text) {
    build_app_manifest_document_from_text(text, Some(config_base_dir(path)))
  })
}

///|
/// Builds an editable manifest document from JSON text.
fn build_app_manifest_document_from_text(
  text : String,
  base_dir : String?,
) -> Result[AppManifestDocument, String] {
  parse_app_manifest_root_object(text).bind(fn(object) {
    build_app_manifest_document_from_object(object, base_dir)
  })
}

///|
/// Wraps a parsed JSON object with both its typed manifest view and raw editable form.
fn build_app_manifest_document_from_object(
  object : Map[String, Json],
  base_dir : String?,
) -> Result[AppManifestDocument, String] {
  build_loaded_manifest_from_json(Json::object(object), base_dir).bind(fn(
    loaded_manifest,
  ) {
    extension_setting_entries_from_object(object).map(fn(_) {
      AppManifestDocument::{ raw_object: object, loaded_manifest }
    })
  })
}

///|
/// Revalidates an edited raw object and rebuilds the document wrapper.
fn refresh_app_manifest_document(
  object : Map[String, Json],
  base_dir : String?,
) -> Result[AppManifestDocument, String] {
  build_app_manifest_document_from_object(object, base_dir)
}

///|
/// Reads manifest text from disk with a labeled error message.
fn read_app_manifest_text(path : String) -> Result[String, String] {
  let manifest_text : Result[String, _] = try? @mbfs.read_file_to_string(path)
  match manifest_text {
    Ok(text) => Ok(text)
    Err(error) => Err("failed to read app manifest: " + error.to_string())
  }
}

///|
/// Parses manifest text and returns the root JSON object.
fn parse_app_manifest_root_object(
  text : String,
) -> Result[Map[String, Json], String] {
  let parsed_json : Result[Json, _] = try? @json.parse(text)
  match parsed_json {
    Err(error) => Err("failed to parse app manifest JSON: " + error.to_string())
    Ok(json) => expect_object(json, "app manifest")
  }
}

///|
/// Extracts and validates the `extensions` object as normalized setting pairs.
fn extension_setting_entries_from_object(
  object : Map[String, Json],
) -> Result[Array[(String, @manifest.ExtensionSetting)], String] {
  let entries : Array[(String, @manifest.ExtensionSetting)] = []
  let seen : Map[String, Bool] = {}
  match object.get("extensions") {
    Some(Object(extension_object)) =>
      for name, value in extension_object {
        let normalized = normalize_keyword(name)
        guard normalized != "" else {
          return Err("app manifest.extensions contains an empty key")
        }
        guard seen.get(name) is None else {
          return Err("duplicate extension setting key: " + name)
        }
        let setting = match build_extension_setting_from_json(name, value) {
          Ok(setting) => setting
          Err(error) => return Err(error)
        }
        seen.set(name, true)
        entries.push((name, setting))
      }
    Some(_) => return Err("expected object for app manifest.extensions")
    None => ()
  }
  Ok(entries)
}
