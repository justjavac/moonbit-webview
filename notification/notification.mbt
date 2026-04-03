///|
pub(all) enum NotificationLevel {
  Info
  Warning
  Error
} derive(Show, Eq)

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
pub fn is_supported() -> Bool {
  is_windows_ffi()
}

///|
pub fn ensure_supported() -> Result[Unit, String] {
  if is_supported() {
    Ok(())
  } else {
    Err("notification package currently supports Windows native builds only")
  }
}

///|
fn ensure_body(body : String) -> Result[String, String] {
  if body.is_empty() {
    Err("notification body must not be empty")
  } else {
    Ok(body)
  }
}

///|
fn level_to_int(level : NotificationLevel) -> Int {
  match level {
    Info => 0
    Warning => 1
    Error => 2
  }
}

///|
fn to_wstr(value : String?) -> Bytes {
  match value {
    Some(value) => @ffi.to_wstr(value)
    None => @ffi.to_wstr("")
  }
}

///|
pub fn show(
  body : String,
  title? : String? = None,
  level? : NotificationLevel = Info,
) -> Result[Unit, String] {
  show_with_window(0, body, title=title, level=level)
}

///|
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

///|
test "notification requires a body" {
  assert_eq(ensure_body(""), Err("notification body must not be empty"))
  assert_eq(ensure_body("ready"), Ok("ready"))
}

///|
test "notification level maps to native code" {
  assert_eq(level_to_int(Info), 0)
  assert_eq(level_to_int(Warning), 1)
  assert_eq(level_to_int(Error), 2)
}
