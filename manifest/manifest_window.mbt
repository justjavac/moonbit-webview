///|
/// Declarative sizing hint used by manifest windows.
pub(all) enum WindowSizeHint {
  None
  Fixed
  Min
  Max
} derive(Debug, Eq)

///|
pub impl Show for WindowSizeHint with output(self, logger) {
  match self {
    None => logger.write_string("None")
    Fixed => logger.write_string("Fixed")
    Min => logger.write_string("Min")
    Max => logger.write_string("Max")
  }
}

///|
/// Declarative window settings loaded from `app.json`.
pub struct WindowManifest {
  title : String
  width : Int
  height : Int
  size_hint : WindowSizeHint
} derive(Debug, Eq)

///|
pub impl Show for WindowManifest with output(self, logger) {
  logger.write_string("WindowManifest::{ title: ")
  logger.write_object(self.title)
  logger.write_string(", width: ")
  logger.write_object(self.width)
  logger.write_string(", height: ")
  logger.write_object(self.height)
  logger.write_string(", size_hint: ")
  logger.write_object(self.size_hint)
  logger.write_string(" }")
}

///|
/// Declarative secondary window entry loaded from `app.json`.
pub struct AppWindowManifest {
  id : String
  window : WindowManifest
  entry : AppEntry
} derive(Debug, Eq)

///|
pub impl Show for AppWindowManifest with output(self, logger) {
  logger.write_string("AppWindowManifest::{ id: ")
  logger.write_object(self.id)
  logger.write_string(", window: ")
  logger.write_object(self.window)
  logger.write_string(", entry: ")
  logger.write_object(self.entry)
  logger.write_string(" }")
}

///|
/// Builds a manifest window configuration.
/// This is the declarative window shape consumed by bootstrap and later turned
/// into runtime `WindowConfig` values.
pub fn WindowManifest::new(
  title : String,
  width : Int,
  height : Int,
  size_hint? : WindowSizeHint = WindowSizeHint::None,
) -> WindowManifest {
  WindowManifest::{ title, width, height, size_hint }
}

///|
/// Builds a declarative secondary window entry.
/// Secondary windows keep their own id, window settings, and entry payload in
/// the manifest document.
pub fn AppWindowManifest::new(
  id : String,
  window : WindowManifest,
  entry : AppEntry,
) -> AppWindowManifest {
  AppWindowManifest::{ id, window, entry }
}
