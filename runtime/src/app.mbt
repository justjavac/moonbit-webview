///|
/// Window runtime owned by an `App`.
pub struct AppWindow {
  id : String
  webview : @webview.Webview
  config : WindowConfig
  entry : AppEntry
}

///|
/// High-level application runtime built on top of one or more `@webview.Webview`
/// instances. The first window is the main window that enters the event loop.
pub struct App {
  main_window : AppWindow
  config : AppConfig
  mut windows : Array[AppWindow]
  installed_extensions : Array[Extension]
  installed_extension_names : Map[String, Bool]
}

///|
/// Creates an application and applies its initial window configuration.
pub fn App::new(config : AppConfig) -> App {
  let main_window = create_app_window(
    "main",
    config.window,
    config.entry,
    config.debug,
  )
  let app = App::{
    main_window,
    config,
    windows: [main_window],
    installed_extensions: [],
    installed_extension_names: {},
  }
  for window in config.windows {
    let _ = app.create_window(window)
  }
  app
}

///|
/// Returns the main app window that owns the runtime loop.
pub fn App::main_window(self : App) -> AppWindow {
  self.main_window
}

///|
/// Returns the underlying low-level webview of the main window.
pub fn App::webview(self : App) -> @webview.Webview {
  self.main_window.webview
}

///|
/// Returns the app configuration used at construction time.
pub fn App::config(self : App) -> AppConfig {
  self.config
}

///|
/// Returns the currently registered windows, including the main window.
pub fn App::windows(self : App) -> Array[AppWindow] {
  self.windows
}

///|
/// Returns a window by its app-level identifier.
pub fn App::window(self : App, id : String) -> AppWindow? {
  for window in self.windows() {
    if window.id == id {
      return Some(window)
    }
  }
  None
}

///|
/// Creates and registers an additional window before the app runtime loop
/// starts. The returned window participates in future extension installs and
/// app-wide event broadcasts.
pub fn App::create_window(self : App, config : AppWindowConfig) -> AppWindow {
  guard config.id != "main" else {
    abort("App::create_window: \"main\" is reserved for the primary window")
  }
  guard self.window(config.id) is None else {
    abort("App::create_window: duplicate window id: " + config.id)
  }
  let window = create_app_window(
    config.id,
    config.window,
    config.entry,
    self.config.debug,
  )
  install_existing_extensions(window.webview, self.installed_extensions())
  self.register_window(window)
  window
}

///|
/// Runs the main window loop after loading every configured window entry.
pub fn App::run(self : App) -> Unit {
  for window in self.windows() {
    load_app_entry(window.webview, window.entry)
  }
  self.main_window.webview.run()
}

///|
/// Destroys every registered window and releases the app runtime.
pub fn App::destroy(self : App) -> Unit {
  let windows = self.windows()
  self.windows = []
  self.installed_extension_names.clear()
  for window in windows {
    window.webview.destroy()
  }
}

///|
/// Returns the application-level window identifier.
pub fn AppWindow::id(self : AppWindow) -> String {
  self.id
}

///|
/// Returns the underlying low-level webview.
pub fn AppWindow::webview(self : AppWindow) -> @webview.Webview {
  self.webview
}

///|
/// Returns the window configuration.
pub fn AppWindow::config(self : AppWindow) -> WindowConfig {
  self.config
}

///|
/// Returns the entry associated with this window.
pub fn AppWindow::entry(self : AppWindow) -> AppEntry {
  self.entry
}
