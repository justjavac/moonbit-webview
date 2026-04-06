///|
/// Declarative extension setting loaded from `app.json`.
pub(all) enum ExtensionSetting {
  Disabled
  Enabled(Json?)
} derive(Eq)

///|
pub impl Show for ExtensionSetting with output(self, logger) {
  match self {
    Disabled => logger.write_string("Disabled")
    Enabled(options) => {
      logger.write_string("Enabled(")
      logger.write_object(options)
      logger.write_string(")")
    }
  }
}

///|
/// Returns whether this setting enables an extension.
/// This treats every `Enabled(...)` variant as active regardless of whether it
/// also carries JSON options.
pub fn ExtensionSetting::is_enabled(self : ExtensionSetting) -> Bool {
  match self {
    Disabled => false
    Enabled(_) => true
  }
}

///|
/// Returns the optional JSON options carried by an enabled extension setting.
/// Disabled settings always return `None` so callers can branch on one accessor.
pub fn ExtensionSetting::options(self : ExtensionSetting) -> Json? {
  match self {
    Disabled => None
    Enabled(options) => options
  }
}

///|
/// Builds an enabled extension setting with optional JSON options.
/// Pass `Some(json)` when the extension needs structured manifest-time
/// configuration.
pub fn ExtensionSetting::enabled(options? : Json? = None) -> ExtensionSetting {
  Enabled(options)
}

///|
/// Builds a disabled extension setting.
/// Use this when the manifest should preserve an explicit opt-out entry.
pub fn ExtensionSetting::disabled() -> ExtensionSetting {
  Disabled
}
