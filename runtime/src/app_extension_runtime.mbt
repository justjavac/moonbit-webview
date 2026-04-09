///|
/// Installs an extension across every currently registered app window.
fn install_app_extension_on_app(app : App, extension : @core.Extension) -> Unit {
  let extension_id = extension.id()
  let extension_namespace = extension.js_namespace()
  let extension_ids = app.installed_extension_ids()
  let extension_namespaces = app.installed_extension_namespaces()
  guard extension_ids.get(extension_id) is None else {
    abort(
      "App::install_extension: extension already installed: " + extension_id,
    )
  }
  guard extension_namespaces.get(extension_namespace) is None else {
    abort(
      "App::install_extension: extension namespace already installed: " +
      extension_namespace,
    )
  }
  extension_ids.set(extension_id, true)
  extension_namespaces.set(extension_namespace, true)
  app.installed_extensions().push(extension)
  for window in app.windows() {
    @core.install_extension(window.webview, extension)
  }
}

///|
/// Broadcasts an extension event to every window owned by the app.
fn[Payload : ToJson] emit_app_extension(
  app : App,
  extension_namespace : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  for window in app.windows() {
    @core.emit_extension(
      window.webview,
      extension_namespace,
      event_name,
      payload,
    )
  }
}

///|
/// Registers a newly created window and wires its destroy hook back into the app.
fn App::register_window(self : App, window : AppWindow) -> Unit {
  self.windows.push(window)
  window.webview.register_destroy_hook(
    app_window_destroy_hook_name(window.id),
    fn() { self.remove_window(window.id) },
  )
}

///|
/// Removes a window from the app runtime after it has been destroyed.
fn App::remove_window(self : App, window_id : String) -> Unit {
  self.windows = exclude_window(self.windows, window_id)
}

///|
/// Returns every window except the one identified by `window_id`.
fn exclude_window(
  windows : Array[AppWindow],
  window_id : String,
) -> Array[AppWindow] {
  let remaining : Array[AppWindow] = []
  for window in windows {
    if window.id != window_id {
      remaining.push(window)
    }
  }
  remaining
}

///|
/// Returns the mutable array of extensions already installed on the app.
fn App::installed_extensions(self : App) -> Array[@core.Extension] {
  self.installed_extensions
}

///|
/// Returns the installed extension id set used for duplicate detection.
fn App::installed_extension_ids(self : App) -> Map[String, Bool] {
  self.installed_extension_ids
}

///|
/// Returns the installed extension namespace set used for duplicate detection.
fn App::installed_extension_namespaces(self : App) -> Map[String, Bool] {
  self.installed_extension_namespaces
}
