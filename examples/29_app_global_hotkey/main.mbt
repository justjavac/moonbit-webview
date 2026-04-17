///|
fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new(
      "MoonBit App Runtime + Global Hotkey",
      960,
      740,
      size_hint=@manifest.WindowSizeHint::None,
    ),
    @manifest.AppEntry::Html(resource),
    debug=1,
  )
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@global_hotkey.spec())
  let app : @wvrt.App = match @app.create_app(manifest, registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
