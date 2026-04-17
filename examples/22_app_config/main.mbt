///|
fn load_app_from_manifest_candidates(
  registry : @app.ExtensionRegistry,
) -> Result[@wvrt.App, String] {
  let candidates = [
    "22_app_config/app.json", "examples/22_app_config/app.json", "../examples/22_app_config/app.json",
    "../../examples/22_app_config/app.json", "../../../examples/22_app_config/app.json",
    "../../../../examples/22_app_config/app.json", "../../../../../examples/22_app_config/app.json",
    "../../../../../../examples/22_app_config/app.json",
  ]
  let mut last_error = "failed to read app manifest: no candidate path matched"
  for candidate in candidates {
    match @app.create_app_from_file(candidate, registry) {
      Ok(app) => return Ok(app)
      Err(error) => last_error = error
    }
  }
  Err(last_error)
}

///|
fn main {
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@fs.spec())
  let _ = registry.register(@path.spec())
  let app : @wvrt.App = match load_app_from_manifest_candidates(registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  app.run()
}
