///|
/// Returns extension ids declared in one editable manifest document.
///
/// By default only enabled extensions are returned. Pass `enabled_only=false`
/// to include disabled entries too.
pub fn declared_extension_ids(
  document : @bootstrap.AppManifestDocument,
  enabled_only? : Bool = true,
) -> Array[String] {
  let ids : Array[String] = []
  for entry in document.extension_settings() {
    let (name, setting) = entry
    if enabled_only {
      if @manifest.ExtensionSetting::is_enabled(setting) {
        ids.push(name)
      }
    } else {
      ids.push(name)
    }
  }
  ids
}
