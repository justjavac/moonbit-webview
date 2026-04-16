///|
test "notification requires a body" {
  assert_eq(ensure_body(""), Err("notification body must not be empty"))
  assert_eq(ensure_body("ready"), Ok("ready"))
}

///|
test "notification level maps to native code" {
  assert_true(
    level_to_native(None) == @sys_notification.NotificationLevel::Info,
  )
  assert_true(
    level_to_native(Some("warning")) ==
    @sys_notification.NotificationLevel::Warning,
  )
  assert_true(
    level_to_native(Some("error")) == @sys_notification.NotificationLevel::Error,
  )
}
