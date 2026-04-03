///|
fn main {
  let config = @bootstrap.BootstrapAppConfig::new(
    @wvrt.WindowConfig::new("MoonBit System Runtime", 1080, 760),
    @wvrt.AppEntry::Html(resource),
    debug=1,
  )
  let app = match
    @app.create_app(
      config,
      extensions=[
        @notification.app_extension(),
        @tray.app_extension(),
        @global_hotkey.app_extension(),
      ],
    ) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
