///|
fn main {
  let config = @bootstrap.BootstrapAppConfig::new(
    @wvrt.WindowConfig::new(
      "MoonBit App Runtime + Dialog + Clipboard",
      900,
      680,
      size_hint=@webview.SizeHint::None,
    ),
    @wvrt.AppEntry::Html(resource),
    debug=1,
  )
  let app = match
    @app.create_app(
      config,
      extensions=[@dialog.app_extension(), @clipboard.app_extension()],
    ) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
