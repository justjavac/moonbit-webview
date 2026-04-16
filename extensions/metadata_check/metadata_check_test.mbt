///|
/// Resolves one fixture path by searching the current directory and its parents.
fn resolve_fixture_path(candidates : Array[String]) -> String {
  let mut prefix = ""
  let mut depth = 0
  while depth < 8 {
    for candidate in candidates {
      let resolved = prefix + candidate
      if @mbfs.path_exists(resolved) {
        return resolved
      }
    }
    prefix = prefix + "../"
    depth = depth + 1
  }
  candidates[0]
}

///|
/// Resolves the metadata file path for one built-in extension fixture.
fn extension_metadata_path(name : String) -> String {
  resolve_fixture_path([
    "../" + name + "/extension.json",
    name + "/extension.json",
    "extensions/" + name + "/extension.json",
  ])
}

///|
/// Loads one built-in extension descriptor and aborts the test on failure.
fn load_descriptor(name : String) -> @catalog.ExtensionDescriptor {
  match
    @catalog.load_extension_descriptor_from_file(extension_metadata_path(name)) {
    Ok(descriptor) => descriptor
    Err(error) => abort(error)
  }
}

///|
/// Asserts that metadata fields stay aligned with the exported extension spec.
fn assert_metadata_matches_spec(
  descriptor : @catalog.ExtensionDescriptor,
  spec : @core.ExtensionSpec,
  package_path : String,
  expected_id : String,
  expected_namespace : String,
) -> Unit raise {
  assert_eq(descriptor.id(), spec.id())
  assert_eq(descriptor.id(), expected_id)
  assert_eq(descriptor.dependencies(), spec.dependencies())
  assert_eq(descriptor.package_path(), package_path)
  assert_eq(descriptor.spec_symbol(), "spec")
  assert_eq(descriptor.manifest_key(), expected_id)
  assert_eq(spec.js_namespace(), expected_namespace)
  assert_eq(descriptor.js_namespace(), expected_namespace)
  assert_true(descriptor.platforms().length() > 0)
  assert_true(descriptor.capabilities().length() > 0)
}

///|
test "built-in extension metadata stays aligned with built-in specs" {
  assert_metadata_matches_spec(
    load_descriptor("clipboard"),
    @clipboard.spec(),
    "extensions/clipboard",
    "justjavac/lepus-clipboard",
    "clipboard",
  )
  assert_metadata_matches_spec(
    load_descriptor("dialog"),
    @dialog.spec(),
    "extensions/dialog",
    "justjavac/lepus-dialog",
    "dialog",
  )
  assert_metadata_matches_spec(
    load_descriptor("fs"),
    @fs.spec(),
    "extensions/fs",
    "justjavac/lepus-fs",
    "fs",
  )
  assert_metadata_matches_spec(
    load_descriptor("global_hotkey"),
    @global_hotkey.spec(),
    "extensions/global_hotkey",
    "justjavac/lepus-global-hotkey",
    "globalHotkey",
  )
  assert_metadata_matches_spec(
    load_descriptor("notification"),
    @notification.spec(),
    "extensions/notification",
    "justjavac/lepus-notification",
    "notification",
  )
  assert_metadata_matches_spec(
    load_descriptor("path"),
    @path.spec(),
    "extensions/path",
    "justjavac/lepus-path",
    "path",
  )
  assert_metadata_matches_spec(
    load_descriptor("shell"),
    @shell.spec(),
    "extensions/shell",
    "justjavac/lepus-shell",
    "shell",
  )
  assert_metadata_matches_spec(
    load_descriptor("tray"),
    @tray.spec(),
    "extensions/tray",
    "justjavac/lepus-tray",
    "tray",
  )
}
