///|
/// Preserves the original JSON document while exposing a typed bootstrap config.
struct AppConfigDocument {
  raw_object : Map[String, Json]
  base_dir : String?
  bootstrap_config : BootstrapAppConfig
}

///|
pub fn AppConfigDocument::config(
  self : AppConfigDocument,
) -> BootstrapAppConfig {
  self.bootstrap_config
}

///|
pub fn AppConfigDocument::extension_option_entries(
  self : AppConfigDocument,
) -> Array[(String, Json)] {
  match extension_option_entries_from_object(self.raw_object) {
    Ok(entries) => entries
    Err(error) =>
      abort("invalid extension options in AppConfigDocument: " + error)
  }
}

///|
pub fn AppConfigDocument::extension_options(
  self : AppConfigDocument,
  name : String,
) -> Json? {
  let entries = self.extension_option_entries()
  for entry in entries {
    let (entry_name, options) = entry
    if entry_name == name {
      return Some(clone_json(options))
    }
  }
  None
}

///|
pub fn AppConfigDocument::to_json(self : AppConfigDocument) -> Json {
  Json::object(clone_json_object(self.raw_object))
}

///|
pub fn AppConfigDocument::to_pretty_json(self : AppConfigDocument) -> String {
  self.to_json().stringify(indent=2) + "\n"
}

///|
fn AppConfigDocument::updated(
  self : AppConfigDocument,
  apply_update : (Map[String, Json]) -> Result[Unit, String],
) -> Result[AppConfigDocument, String] {
  let updated_object = clone_json_object(self.raw_object)
  match apply_update(updated_object) {
    Err(error) => Err(error)
    Ok(_) => refresh_app_config_document(updated_object, self.base_dir)
  }
}
