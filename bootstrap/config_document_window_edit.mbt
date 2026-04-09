///|
/// Replaces the top-level main window declaration.
/// The updated document is normalized back through the typed manifest parser
/// before it is returned to the caller.
pub fn AppManifestDocument::set_window(
  self : AppManifestDocument,
  window : @manifest.WindowManifest,
) -> Result[AppManifestDocument, String] {
  self.updated(object => {
    object["window"] = window_manifest_to_json(window)
    Ok(())
  })
}
