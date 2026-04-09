///|
/// Parses a declarative app manifest from a JSON string.
/// This convenience wrapper is useful when callers only need the typed manifest
/// result and do not need to preserve the original editable JSON document.
pub fn load_app_manifest_from_json(
  text : String,
) -> Result[LoadedAppManifest, String] {
  load_app_manifest_document_from_json(text).map(fn(document) {
    document.loaded_manifest()
  })
}

///|
/// Reads and parses a declarative app manifest from a JSON file.
/// Relative file entries are rebased against the manifest file's directory
/// before the loaded manifest is returned.
pub fn load_app_manifest_from_file(
  path : String,
) -> Result[LoadedAppManifest, String] {
  load_app_manifest_document_from_file(path).map(fn(document) {
    document.loaded_manifest()
  })
}
