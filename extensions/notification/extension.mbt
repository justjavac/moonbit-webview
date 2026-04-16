///|
let extension_id = "justjavac/lepus-notification"

///|
let extension_namespace = "notification"

///|
struct NotificationPayload {
  title : String?
  body : String
  level : String?
} derive(ToJson, FromJson, Debug, Eq)

///|
struct NotificationReply {
  shown : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct NotificationActivity {
  operation : String
  title : String?
  level : String?
} derive(ToJson, FromJson, Debug, Eq)

///|
/// Verifies that native notification support is available on this platform.
fn ensure_supported() -> Result[Unit, String] {
  @sys_notification.ensure_supported()
}

///|
/// Runs a notification operation only when the platform is supported.
fn[Reply] with_supported(
  callback : () -> Result[Reply, String],
) -> Result[Reply, String] {
  ensure_supported().bind(fn(_) { callback() })
}

///|
/// Rejects empty notification bodies before calling the native package.
fn ensure_body(body : String) -> Result[String, String] {
  if body.is_empty() {
    Err("notification body must not be empty")
  } else {
    Ok(body)
  }
}

///|
/// Maps the public notification level string to the native enum.
fn level_to_native(level : String?) -> @sys_notification.NotificationLevel {
  match level {
    Some("warning") => @sys_notification.NotificationLevel::Warning
    Some("error") => @sys_notification.NotificationLevel::Error
    _ => @sys_notification.NotificationLevel::Info
  }
}

///|
/// Emits a notification activity event for JavaScript listeners.
fn emit_activity(
  extension : @core.ExtensionContext,
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
/// Shows one native notification and converts the result into the extension reply shape.
fn show_notification(
  payload : NotificationPayload,
) -> Result[NotificationReply, String] {
  ensure_body(payload.body).bind(fn(body) {
    @sys_notification.show(
      body,
      title=payload.title,
      level=level_to_native(payload.level),
    ).map(fn(_) { NotificationReply::{ shown: true } })
  })
}

///|
/// Builds the `notification` extension for direct installation.
/// Install it manually when trusted local content needs native notification
/// delivery without a declarative registry step.
pub fn extension() -> @core.Extension {
  @core.Extension::new(extension_id, extension_namespace, fn(extension) {
    extension.op_result("show", fn(payload : NotificationPayload) {
      with_supported(fn() {
        show_notification(payload).map(fn(reply) {
          emit_activity(extension, payload.title, payload.level)
          reply
        })
      })
    })
  })
}

///|
/// Builds the declarative `notification` extension spec.
/// Register this when notification support should be selected through app
/// composition or tooling workflows.
pub fn spec() -> @core.ExtensionSpec {
  @core.ExtensionSpec::new(extension_id, extension_namespace, fn(_context) {
    Ok(extension())
  })
}
