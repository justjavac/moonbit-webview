///|
fn config_document_options_map(
  document : @bootstrap.AppConfigDocument,
) -> Map[String, Json] {
  let options_by_extension : Map[String, Json] = {}
  for entry in document.extension_option_entries() {
    let (name, options) = entry
    options_by_extension.set(name, options)
  }
  options_by_extension
}

///|
fn validate_declared_extension_options(
  options_by_extension : Map[String, Json],
  extensions_by_name : Map[String, AppExtension],
) -> Result[Unit, String] {
  for name, _ in options_by_extension {
    guard extensions_by_name.get(name) is Some(_) else {
      return Err("unknown extension options key: " + name)
    }
  }
  Ok(())
}
