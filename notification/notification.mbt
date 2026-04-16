///|
pub(all) enum NotificationLevel {
  Info
  Warning
  Error
} derive(Debug, Eq)

///|
extern "C" fn is_windows_ffi() -> Bool = "desktop_notification_is_windows"

///|
#borrow(title, body)
extern "C" fn show_notification_ffi(
  window : Int64,
  title : Bytes,
  body : Bytes,
  level : Int,
) -> Bool = "desktop_notification_show"

///|
/// Returns whether the notification package supports the current platform.
pub fn is_supported() -> Bool {
  is_windows_ffi()
}

///|
/// Fails with a descriptive error when notifications are unsupported on this platform.
pub fn ensure_supported() -> Result[Unit, String] {
  if is_supported() {
    Ok(())
  } else {
    Err("notification package currently supports Windows native builds only")
  }
}

///|
/// Rejects empty notification bodies before calling the native API.
fn ensure_body(body : String) -> Result[String, String] {
  if body.is_empty() {
    Err("notification body must not be empty")
  } else {
    Ok(body)
  }
}

///|
/// Maps the public notification level enum to the native integer code.
fn level_to_int(level : NotificationLevel) -> Int {
  match level {
    Info => 0
    Warning => 1
    Error => 2
  }
}

///|
/// Encodes an optional string as a UTF-16 buffer for the native API.
fn to_wstr(value : String?) -> Bytes {
  match value {
    Some(value) => @ffi.to_wstr(value)
    None => @ffi.to_wstr("")
  }
}

///|
/// Shows a notification without binding it to a specific window handle.
///
/// Parameters:
/// - `body` - The required notification body text.
/// - `title` - Optional title displayed by the platform notification center.
/// - `level` - Visual importance level used by the native notification backend.
pub fn show(
  body : String,
  title? : String? = None,
  level? : NotificationLevel = Info,
) -> Result[Unit, String] {
  show_with_window(0, body, title~, level~)
}

///|
/// Shows a notification associated with a specific native window handle.
///
/// Parameters:
/// - `window_handle` - The native parent window handle or `0` when no parent is needed.
/// - `body` - The required notification body text.
/// - `title` - Optional title displayed by the platform notification center.
/// - `level` - Visual importance level used by the native notification backend.
pub fn show_with_window(
  window_handle : Int64,
  body : String,
  title? : String? = None,
  level? : NotificationLevel = Info,
) -> Result[Unit, String] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) =>
      match ensure_body(body) {
        Err(error) => Err(error)
        Ok(body) =>
          if show_notification_ffi(
              window_handle,
              to_wstr(title),
              @ffi.to_wstr(body),
              level_to_int(level),
            ) {
            Ok(())
          } else {
            Err("notification.show failed")
          }
      }
  }
}
