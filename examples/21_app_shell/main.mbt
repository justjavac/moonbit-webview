///|
fn main {
  let config = @bootstrap.BootstrapAppConfig::new(
    @wvrt.WindowConfig::new(
      "MoonBit App Runtime + Shell",
      860,
      620,
      size_hint=@webview.SizeHint::None,
    ),
    @wvrt.AppEntry::Html(resource),
    debug=1,
  )
  let app = match @app.create_app(config, extensions=[@shell.app_extension()]) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
