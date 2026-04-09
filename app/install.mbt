///|
/// Builds a runtime app from previously prepared internal app state.
fn build_prepared_app(prepared : PreparedApp) -> Result[@wvrt.App, String] {
  let app = @wvrt.App::new(prepared.runtime_config())
  match
    install_prepared_extensions(
      app,
      prepared.prepared_extensions(),
      prepared.base_dir(),
    ) {
    Ok(_) => Ok(app)
    Err(error) => {
      app.destroy()
      Err(error)
    }
  }
}

///|
/// Builds and installs every prepared extension into the runtime app.
fn install_prepared_extensions(
  app : @wvrt.App,
  prepared_extensions : Array[PreparedExtension],
  base_dir : String?,
) -> Result[Unit, String] {
  for prepared_extension in prepared_extensions {
    match install_prepared_extension(app, prepared_extension, base_dir) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
/// Builds and installs one prepared extension, validating the declared spec name.
fn install_prepared_extension(
  app : @wvrt.App,
  prepared_extension : PreparedExtension,
  base_dir : String?,
) -> Result[Unit, String] {
  let prepared_id = prepared_extension.id()
  let prepared_namespace = prepared_extension.js_namespace()
  let extension = match prepared_extension.build(base_dir) {
    Ok(extension) => extension
    Err(error) =>
      return Err("failed to build extension " + prepared_id + ": " + error)
  }
  guard extension.id() == prepared_id else {
    return Err(
      "extension spec id mismatch: declared " +
      prepared_id +
      " but built " +
      extension.id(),
    )
  }
  guard extension.js_namespace() == prepared_namespace else {
    return Err(
      "extension spec namespace mismatch: declared " +
      prepared_namespace +
      " but built " +
      extension.js_namespace(),
    )
  }
  app.install_extension(extension)
  Ok(())
}
