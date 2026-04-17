///|
fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new(
      "MoonBit App Runtime + Dialog + Clipboard",
      900,
      680,
      size_hint=@manifest.WindowSizeHint::None,
    ),
    @manifest.AppEntry::Html(resource),
    debug=1,
  )
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@dialog.spec())
  let _ = registry.register(@clipboard.spec())
  let app : @wvrt.App = match @app.create_app(manifest, registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
