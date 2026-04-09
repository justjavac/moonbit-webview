///|
/// Replaces the top-level app entry declaration.
/// This keeps the rest of the document intact while revalidating the updated
/// entry shape against the typed manifest model.
pub fn AppManifestDocument::set_entry(
  self : AppManifestDocument,
  entry : @manifest.AppEntry,
) -> Result[AppManifestDocument, String] {
  self.updated(object => {
    object["entry"] = app_entry_to_json(entry)
    Ok(())
  })
}
