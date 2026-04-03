///|
struct NotificationPayload {
  title : String?
  body : String
  level : String?
} derive(ToJson, FromJson, Show, Eq)

///|
struct NotificationReply {
  shown : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct NotificationActivity {
  operation : String
  title : String?
  level : String?
} derive(ToJson, FromJson, Show, Eq)

///|
fn ensure_supported() -> Result[Unit, String] {
  @sys_notification.ensure_supported()
}

///|
fn[Reply] with_supported(
  callback : () -> Result[Reply, String],
) -> Result[Reply, String] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) => callback()
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
fn level_to_native(level : String?) -> @sys_notification.NotificationLevel {
  match level {
    Some("warning") => @sys_notification.NotificationLevel::Warning
    Some("error") => @sys_notification.NotificationLevel::Error
    _ => @sys_notification.NotificationLevel::Info
  }
}

///|
fn emit_activity(
  extension : @runtime.ExtensionContext,
  title : String?,
  level : String?,
) -> Unit {
  extension.emit("activity", NotificationActivity::{
    operation: "show",
    title,
    level,
  })
}

///|
fn show_notification(
  payload : NotificationPayload,
) -> Result[NotificationReply, String] {
  match ensure_body(payload.body) {
    Err(error) => Err(error)
    Ok(body) =>
      match
        @sys_notification.show(
          body,
          title=payload.title,
          level=level_to_native(payload.level),
        ) {
        Err(error) => Err(error)
        Ok(_) => Ok(NotificationReply::{ shown: true })
      }
  }
}

///|
/// Builds the `notification` extension for new application code.
pub fn extension() -> @runtime.Extension {
  @runtime.Extension::new("notification", fn(extension) {
    extension.op_result("show", fn(payload : NotificationPayload) {
      with_supported(fn() {
        match show_notification(payload) {
          Err(error) => Err(error)
          Ok(reply) => {
            emit_activity(extension, payload.title, payload.level)
            Ok(reply)
          }
        }
      })
    })
  })
}

///|
pub fn app_extension() -> @app.AppExtension {
  @app.AppExtension::new("notification", fn(_context) { Ok(extension()) })
}

///|
test "notification requires a body" {
  assert_eq(ensure_body(""), Err("notification body must not be empty"))
  assert_eq(ensure_body("ready"), Ok("ready"))
}

///|
test "notification level maps to native code" {
  assert_eq(level_to_native(None), @sys_notification.NotificationLevel::Info)
  assert_eq(
    level_to_native(Some("warning")),
    @sys_notification.NotificationLevel::Warning,
  )
  assert_eq(
    level_to_native(Some("error")),
    @sys_notification.NotificationLevel::Error,
  )
}
