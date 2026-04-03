///|
pub fn create_app(
  config : @bootstrap.BootstrapAppConfig,
  extensions? : Array[AppExtension] = [],
) -> Result[@wvrt.App, String] {
  let by_name = match extension_map(extensions) {
    Ok(by_name) => by_name
    Err(error) => return Err(error)
  }
  let app = @wvrt.App::new(runtime_config_from_bootstrap(config))
  match validate_declared_extension_options({}, by_name) {
    Ok(_) => ()
    Err(error) => {
      app.destroy()
      return Err(error)
    }
  }
  match install_declared_extensions(app, config, extensions, {}) {
    Ok(_) => Ok(app)
    Err(error) => {
      app.destroy()
      Err(error)
    }
  }
}

///|
pub fn create_app_from_json(
  text : String,
  extensions? : Array[AppExtension] = [],
) -> Result[@wvrt.App, String] {
  match @bootstrap.load_app_config_document_from_json(text) {
    Err(error) => Err(error)
    Ok(document) => create_app_from_document(document, extensions)
  }
}

///|
pub fn create_app_from_file(
  path : String,
  extensions? : Array[AppExtension] = [],
) -> Result[@wvrt.App, String] {
  match @bootstrap.load_app_config_document_from_file(path) {
    Err(error) => Err(error)
    Ok(document) => create_app_from_document(document, extensions)
  }
}

///|
fn create_app_from_document(
  document : @bootstrap.AppConfigDocument,
  extensions : Array[AppExtension],
) -> Result[@wvrt.App, String] {
  let by_name = match extension_map(extensions) {
    Ok(by_name) => by_name
    Err(error) => return Err(error)
  }
  let options_by_extension = config_document_options_map(document)
  match validate_declared_extension_options(options_by_extension, by_name) {
    Err(error) => Err(error)
    Ok(_) => {
      let config = document.config()
      let app = @wvrt.App::new(runtime_config_from_bootstrap(config))
      match
        install_declared_extensions(
          app, config, extensions, options_by_extension,
        ) {
        Ok(_) => Ok(app)
        Err(error) => {
          app.destroy()
          Err(error)
        }
      }
    }
  }
}

///|
fn runtime_config_from_bootstrap(
  config : @bootstrap.BootstrapAppConfig,
) -> @wvrt.AppConfig {
  @wvrt.AppConfig::new(
    config.window,
    config.entry,
    debug=config.debug,
    windows=config.windows,
  )
}
