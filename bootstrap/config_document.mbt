///|
/// Preserves the original JSON document while exposing a typed manifest view.
struct AppManifestDocument {
  raw_object : Map[String, Json]
  loaded_manifest : LoadedAppManifest
}

///|
/// Returns the typed loaded manifest derived from this editable document.
/// Use this when you need both the normalized manifest and file-origin
/// metadata such as the preserved base directory.
pub fn AppManifestDocument::loaded_manifest(
  self : AppManifestDocument,
) -> LoadedAppManifest {
  self.loaded_manifest
}

///|
/// Returns the typed manifest derived from this editable document.
/// This drops the document-editing wrapper and exposes only the declarative
/// runtime-facing manifest shape.
pub fn AppManifestDocument::manifest(
  self : AppManifestDocument,
) -> @manifest.AppManifest {
  self.loaded_manifest.manifest()
}

///|
/// Returns the manifest base directory associated with this document.
/// Relative file entries and extension build contexts should resolve against
/// this directory when the manifest came from disk.
pub fn AppManifestDocument::base_dir(self : AppManifestDocument) -> String? {
  self.loaded_manifest.base_dir()
}

///|
/// Returns every extension setting preserved from the original JSON document.
/// Entries are revalidated and normalized through the same parsing path used
/// during manifest loading.
pub fn AppManifestDocument::extension_settings(
  self : AppManifestDocument,
) -> Array[(String, @manifest.ExtensionSetting)] {
  match extension_setting_entries_from_object(self.raw_object) {
    Ok(entries) => entries
    Err(error) =>
      abort("invalid extension settings in AppManifestDocument: " + error)
  }
}

///|
/// Returns one preserved extension setting by name, if present.
/// This avoids rebuilding a separate map when tooling only needs to inspect
/// one specific extension key.
pub fn AppManifestDocument::extension_setting(
  self : AppManifestDocument,
  name : String,
) -> @manifest.ExtensionSetting? {
  for entry in self.extension_settings() {
    let (entry_name, setting) = entry
    if entry_name == name {
      return Some(setting)
    }
  }
  None
}

///|
/// Reconstructs the preserved raw manifest document as a JSON object.
/// The returned JSON value is detached from the document so callers can mutate
/// it without affecting future document operations.
pub fn AppManifestDocument::to_json(self : AppManifestDocument) -> Json {
  Json::object(clone_json_object(self.raw_object))
}

///|
/// Serializes the preserved manifest document using two-space indentation.
/// This is the preferred output form when writing edited manifest documents
/// back to disk for review.
pub fn AppManifestDocument::to_pretty_json(
  self : AppManifestDocument,
) -> String {
  self.to_json().stringify(indent=2) + "\n"
}

///|
/// Clones the raw document, applies an update, and rebuilds the typed manifest view.
fn AppManifestDocument::updated(
  self : AppManifestDocument,
  apply_update : (Map[String, Json]) -> Result[Unit, String],
) -> Result[AppManifestDocument, String] {
  let updated_object = clone_json_object(self.raw_object)
  match apply_update(updated_object) {
    Err(error) => Err(error)
    Ok(_) => refresh_app_manifest_document(updated_object, self.base_dir())
  }
}
