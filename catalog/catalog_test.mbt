///|
test "builtin extension info exposes import metadata for tooling" {
  let fs_info = match builtin_extension_info("fs") {
    Some(info) => info
    None => abort("expected fs info")
  }
  assert_eq(fs_info.id(), "fs")
  assert_eq(fs_info.import_path(), "extensions/fs")
  assert_eq(fs_info.import_alias(), "ext_fs")
  assert_eq(fs_info.support_modules(), [])
  assert_eq(fs_info.name(), "Filesystem")
  assert_true(fs_info.description().contains("filesystem"))
}

///|
test "builtin extension info exposes support modules for vendoring" {
  let notification_info = match builtin_extension_info("notification") {
    Some(info) => info
    None => abort("expected notification info")
  }
  assert_eq(notification_info.support_modules().length(), 1)
  let support_module = notification_info.support_modules()[0]
  assert_eq(support_module.dependency_name(), "justjavac/notification")
  assert_eq(support_module.module_dir(), "notification")
}

///|
test "builtin extension info uses exact ids" {
  assert_eq(
    builtin_extension_info("notification"),
    Some(builtin_extensions()[5]),
  )
  assert_eq(builtin_extension_info(" notification "), None)
  assert_eq(builtin_extension_info("global_hotkey"), None)
  assert_eq(builtin_extension_info("custom.echo"), None)
}
