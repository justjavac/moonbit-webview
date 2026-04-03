///|
fn install_declared_extensions(
  app : @wvrt.App,
  config : @bootstrap.BootstrapAppConfig,
  extensions : Array[AppExtension],
  options_by_extension : Map[String, Json],
) -> Result[Unit, String] {
  let ordered = match ordered_extensions(extensions) {
    Ok(ordered) => ordered
    Err(error) => return Err(error)
  }
  for extension in ordered {
    let extension_name = extension.name()
    let context = AppExtensionContext::new(
      options=options_by_extension.get(extension_name),
      base_dir=config.base_dir,
    )
    match extension.build_extension(context) {
      Err(error) =>
        return Err(
          "failed to build app extension " + extension_name + ": " + error,
        )
      Ok(runtime_extension) => {
        guard runtime_extension.name() == extension_name else {
          return Err(
            "app extension name mismatch: declared " +
            extension_name +
            " but built " +
            runtime_extension.name(),
          )
        }
        app.install_extension(runtime_extension)
      }
    }
  }
  Ok(())
}
