///|
fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new(
      "MoonBit App Runtime + FS + Path",
      980,
      720,
      size_hint=@manifest.WindowSizeHint::None,
    ),
    @manifest.AppEntry::Html(resource),
    debug=1,
    extensions={
      "justjavac/lepus-path": @manifest.ExtensionSetting::enabled(),
      "justjavac/lepus-fs": @manifest.ExtensionSetting::enabled(),
    },
  )
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@path.spec())
  let _ = registry.register(@fs.spec())
  let app : @wvrt.App = match @app.create_app(manifest, registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
