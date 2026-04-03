///|
/// Parses a declarative app config from a JSON string.
pub fn load_app_config_from_json(
  text : String,
) -> Result[BootstrapAppConfig, String] {
  match load_app_config_document_from_json(text) {
    Ok(document) => Ok(document.config())
    Err(error) => Err(error)
  }
}

///|
/// Reads and parses a declarative app config from a JSON file.
///
/// Relative `entry.file` values and extension options such as filesystem roots
/// are resolved against the directory that contains the config file.
pub fn load_app_config_from_file(
  path : String,
) -> Result[BootstrapAppConfig, String] {
  match load_app_config_document_from_file(path) {
    Ok(document) => Ok(document.config())
    Err(error) => Err(error)
  }
}
