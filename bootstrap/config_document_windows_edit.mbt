///|
/// Inserts or replaces one secondary window by id.
/// Existing windows keep their relative order, and matching ids are replaced in
/// place so serialized output stays stable across edits.
pub fn AppManifestDocument::upsert_window(
  self : AppManifestDocument,
  window : @manifest.AppWindowManifest,
) -> Result[AppManifestDocument, String] {
  guard normalize_keyword(window.id) != "" else {
    return Err("window id must not be empty")
  }
  self.updated(object => {
    let windows = ensure_windows_json_array(object)
    let window_json = app_window_manifest_to_json(window)
    let mut replaced = false
    for index, existing in windows {
      if window_id_from_json(existing) == Some(window.id) {
        windows[index] = window_json
        replaced = true
        break
      }
    }
    if !replaced {
      windows.push(window_json)
    }
    Ok(())
  })
}

///|
/// Removes one secondary window entry by id and drops the parent array when empty.
/// This keeps the raw JSON compact by removing the `windows` field entirely once
/// no secondary windows remain.
pub fn AppManifestDocument::remove_window(
  self : AppManifestDocument,
  id : String,
) -> Result[AppManifestDocument, String] {
  guard normalize_keyword(id) != "" else {
    return Err("window id must not be empty")
  }
  self.updated(object => {
    match object.get("windows") {
      Some(Array(windows)) => {
        let kept : Array[Json] = []
        for existing in windows {
          if window_id_from_json(existing) != Some(id) {
            kept.push(clone_json(existing))
          }
        }
        if kept.is_empty() {
          object.remove("windows")
        } else {
          object["windows"] = Json::array(kept)
        }
      }
      _ => ()
    }
    Ok(())
  })
}
