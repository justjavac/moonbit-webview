///|
fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new("MoonBit Multi-Window", 980, 680),
    @manifest.AppEntry::File("24_app_multi_window/main_window.html"),
    windows=[
      @manifest.AppWindowManifest::new(
        "docs",
        @manifest.WindowManifest::new(
          "MoonBit Multi-Window Docs",
          720,
          560,
          size_hint=@manifest.WindowSizeHint::None,
        ),
        @manifest.AppEntry::File("24_app_multi_window/docs_window.html"),
      ),
    ],
    debug=1,
  )
  let app : @wvrt.App = match
    @app.create_app(manifest, @app.ExtensionRegistry::new()) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
