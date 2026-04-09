///|
/// Replaces the top-level debug value.
/// The updated document is reparsed before being returned so invalid edits are
/// rejected immediately.
pub fn AppManifestDocument::set_debug(
  self : AppManifestDocument,
  debug : Int,
) -> Result[AppManifestDocument, String] {
  self.updated(object => {
    object["debug"] = ToJson::to_json(debug)
    Ok(())
  })
}
