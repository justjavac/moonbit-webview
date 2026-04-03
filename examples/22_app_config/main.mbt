///|
fn main {
  let app : @wvrt.App = match
    @app.create_app_from_file("22_app_config/app.json", extensions=[
      @fs.app_extension(),
      @path.app_extension(),
    ]) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
