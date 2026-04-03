///|
fn main {
  let config = @bootstrap.BootstrapAppConfig::new(
    @wvrt.WindowConfig::new(
      "MoonBit Ops Runtime",
      980,
      720,
      size_hint=@webview.SizeHint::None,
    ),
    @wvrt.AppEntry::Html(resource),
    debug=1,
  )
  let app = match
    @app.create_app(config, extensions=[
      @fs.app_extension(),
      @path.app_extension(),
    ]) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
