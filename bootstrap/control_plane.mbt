///|
/// Parses one editable manifest control-plane document from JSON text.
pub fn parse_document(text : String) -> Result[AppManifestDocument, String] {
  build_app_manifest_document_from_text(text, None)
}

///|
/// Loads one editable manifest control-plane document from disk.
pub fn load_document(path : String) -> Result[AppManifestDocument, String] {
  read_app_manifest_text(path).bind(fn(text) {
    build_app_manifest_document_from_text(text, Some(config_base_dir(path)))
  })
}

///|
/// Renders one manifest document using the standard pretty JSON layout.
pub fn render_document(document : AppManifestDocument) -> String {
  document.to_pretty_json()
}

///|
/// Writes one manifest document back to disk.
pub fn write_document(
  path : String,
  document : AppManifestDocument,
) -> Result[Unit, String] {
  let write_result : Result[Unit, _] = try? @mbfs.write_string_to_file(
    path,
    render_document(document),
  )
  write_result.map_err(fn(error) {
    "failed to write app manifest: " + error.to_string()
  })
}

///|
/// Revalidates one document through the manifest parser.
pub fn validate_document(
  document : AppManifestDocument,
) -> Result[Unit, String] {
  refresh_app_manifest_document(
    clone_json_object(document.raw_object),
    document.base_dir(),
  ).map(fn(_) { () })
}

///|
/// Normalizes one document by rendering and reparsing it through the control plane.
pub fn normalize_document(
  document : AppManifestDocument,
) -> Result[AppManifestDocument, String] {
  parse_document(render_document(document)).bind(fn(normalized) {
    refresh_app_manifest_document(
      clone_json_object(normalized.raw_object),
      document.base_dir(),
    )
  })
}

///|
/// Replaces the top-level main window title.
pub fn set_window_title(
  document : AppManifestDocument,
  title : String,
) -> Result[AppManifestDocument, String] {
  let window = document.manifest().window
  document.set_window(
    @manifest.WindowManifest::new(
      title,
      window.width,
      window.height,
      size_hint=window.size_hint,
    ),
  )
}

///|
/// Replaces the top-level main window size while preserving the size hint by default.
pub fn set_window_size(
  document : AppManifestDocument,
  width : Int,
  height : Int,
  size_hint? : @manifest.WindowSizeHint? = None,
) -> Result[AppManifestDocument, String] {
  let window = document.manifest().window
  let size_hint = match size_hint {
    Some(size_hint) => size_hint
    None => window.size_hint
  }
  document.set_window(
    @manifest.WindowManifest::new(window.title, width, height, size_hint~),
  )
}

///|
/// Replaces the top-level entry.
pub fn set_entry(
  document : AppManifestDocument,
  entry : @manifest.AppEntry,
) -> Result[AppManifestDocument, String] {
  document.set_entry(entry)
}

///|
/// Replaces the top-level debug value.
pub fn set_debug(
  document : AppManifestDocument,
  debug : Int,
) -> Result[AppManifestDocument, String] {
  document.set_debug(debug)
}

///|
/// Enables one extension in the manifest control plane.
pub fn enable_extension(
  document : AppManifestDocument,
  extension_id : String,
  options? : Json? = None,
) -> Result[AppManifestDocument, String] {
  document.enable_extension(extension_id, options~)
}

///|
/// Disables one extension in the manifest control plane.
pub fn disable_extension(
  document : AppManifestDocument,
  extension_id : String,
) -> Result[AppManifestDocument, String] {
  document.disable_extension(extension_id)
}

///|
/// Removes one extension entry from the manifest control plane.
pub fn remove_extension(
  document : AppManifestDocument,
  extension_id : String,
) -> Result[AppManifestDocument, String] {
  document.remove_extension_setting(extension_id)
}

///|
/// Returns the stored options for one extension, when present and enabled.
pub fn get_extension_options(
  document : AppManifestDocument,
  extension_id : String,
) -> Json? {
  match document.extension_setting(extension_id) {
    Some(setting) => setting.options()
    None => None
  }
}

///|
/// Replaces the stored options for one extension and keeps it enabled.
pub fn set_extension_options(
  document : AppManifestDocument,
  extension_id : String,
  options : Json,
) -> Result[AppManifestDocument, String] {
  document.set_extension_setting(
    extension_id,
    @manifest.ExtensionSetting::enabled(options=Some(options)),
  )
}
