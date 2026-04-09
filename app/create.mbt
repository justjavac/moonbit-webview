///|
/// Prepares internal app creation state from an already parsed manifest.
fn prepare_app(
  manifest : @manifest.AppManifest,
  registry : ExtensionRegistry,
  base_dir? : String? = None,
) -> Result[PreparedApp, String] {
  match plan_extensions(manifest, registry) {
    Err(error) => Err(error)
    Ok(extensions) =>
      Ok(
        PreparedApp::new(
          runtime_config_from_manifest(manifest),
          extensions,
          base_dir~,
        ),
      )
  }
}

///|
/// Creates a runtime app from an already parsed manifest and extension registry.
/// This resolves declarative extensions, prepares the runtime config, and then
/// builds the final `@wvrt.App` in one step.
pub fn create_app(
  manifest : @manifest.AppManifest,
  registry : ExtensionRegistry,
  base_dir? : String? = None,
) -> Result[@wvrt.App, String] {
  match prepare_app(manifest, registry, base_dir~) {
    Err(error) => Err(error)
    Ok(prepared) => build_prepared_app(prepared)
  }
}

///|
/// Builds an app from one parsed control-plane manifest document.
/// The document's preserved base directory is forwarded so relative file paths
/// and extension build contexts resolve the same way they would on disk.
fn create_app_from_document(
  document : @bootstrap.AppManifestDocument,
  registry : ExtensionRegistry,
) -> Result[@wvrt.App, String] {
  create_app(document.manifest(), registry, base_dir=document.base_dir())
}

///|
/// Loads a manifest document from disk and creates a runtime app.
/// Relative file entries and extension base directories are resolved from the
/// manifest file's parent directory before the runtime app is constructed.
pub fn create_app_from_file(
  path : String,
  registry : ExtensionRegistry,
) -> Result[@wvrt.App, String] {
  match @bootstrap.load_document(path) {
    Err(error) => Err(error)
    Ok(document) => create_app_from_document(document, registry)
  }
}
