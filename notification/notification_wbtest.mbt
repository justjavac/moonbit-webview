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
