///|
fn install_app_extension_on_app(app : App, extension : Extension) -> Unit {
  let name = extension.name()
  let extension_names = app.installed_extension_names()
  guard extension_names.get(name) is None else {
    abort("App::install_extension: extension already installed: " + name)
  }
  extension_names.set(name, true)
  app.installed_extensions().push(extension)
  for window in app.windows() {
    install_extension(window.webview, extension)
  }
}

///|
fn[Payload : ToJson] emit_app_extension(
  app : App,
  extension_name : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  for window in app.windows() {
    emit_extension(window.webview, extension_name, event_name, payload)
  }
}

///|
fn App::register_window(self : App, window : AppWindow) -> Unit {
  self.windows.push(window)
  window.webview.register_destroy_hook(
    app_window_destroy_hook_name(window.id),
    fn() { self.remove_window(window.id) },
  )
}

///|
fn App::remove_window(self : App, window_id : String) -> Unit {
  self.windows = exclude_window(self.windows, window_id)
}

///|
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
fn App::installed_extensions(self : App) -> Array[Extension] {
  self.installed_extensions
}

///|
fn App::installed_extension_names(self : App) -> Map[String, Bool] {
  self.installed_extension_names
}
