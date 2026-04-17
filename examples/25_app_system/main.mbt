///|
fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new("MoonBit System Runtime", 1080, 760),
    @manifest.AppEntry::Html(resource),
    debug=1,
  )
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@notification.spec())
  let _ = registry.register(@tray.spec())
  let _ = registry.register(@global_hotkey.spec())
  let app : @wvrt.App = match @app.create_app(manifest, registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
