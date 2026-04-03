///|
/// Entry content loaded by an `App`.
pub(all) enum AppEntry {
  Html(String)
  Url(String)
  File(String)
}

///|
/// Window settings used when creating an `App`.
pub struct WindowConfig {
  title : String
  width : Int
  height : Int
  size_hint : @webview.SizeHint
} derive(Show)

///|
/// Additional window registered on an `App` before the runtime loop starts.
pub struct AppWindowConfig {
  id : String
  window : WindowConfig
  entry : AppEntry
}

///|
/// Application-level settings for the runtime core.
pub struct AppConfig {
  window : WindowConfig
  entry : AppEntry
  windows : Array[AppWindowConfig]
  debug : Int
}

///|
/// Builds a window configuration.
pub fn WindowConfig::new(
  title : String,
  width : Int,
  height : Int,
  size_hint? : @webview.SizeHint = @webview.SizeHint::None,
) -> WindowConfig {
  WindowConfig::{ title, width, height, size_hint }
}

///|
/// Describes a secondary app window.
pub fn AppWindowConfig::new(
  id : String,
  window : WindowConfig,
  entry : AppEntry,
) -> AppWindowConfig {
  AppWindowConfig::{ id, window, entry }
}

///|
/// Builds a runtime-core application configuration.
pub fn AppConfig::new(
  window : WindowConfig,
  entry : AppEntry,
  debug? : Int = 0,
  windows? : Array[AppWindowConfig] = [],
) -> AppConfig {
  AppConfig::{ window, entry, windows, debug }
}
