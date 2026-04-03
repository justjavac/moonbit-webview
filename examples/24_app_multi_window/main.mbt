///|
fn main {
  let config = @bootstrap.BootstrapAppConfig::new(
    @wvrt.WindowConfig::new("MoonBit Multi-Window", 980, 680),
    @wvrt.AppEntry::File("24_app_multi_window/main_window.html"),
    windows=[
      @wvrt.AppWindowConfig::new(
        "docs",
        @wvrt.WindowConfig::new(
          "MoonBit Multi-Window Docs",
          720,
          560,
          size_hint=@webview.SizeHint::None,
        ),
        @wvrt.AppEntry::File("24_app_multi_window/docs_window.html"),
      ),
    ],
    debug=1,
  )
  let app = match @app.create_app(config) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
