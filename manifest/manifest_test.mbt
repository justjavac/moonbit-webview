///|
test "extension setting helpers preserve enabled state and options" {
  let options = Json::object({ "scope": Json::string("read") })
  let enabled = ExtensionSetting::enabled(options=Some(options))
  assert_true(enabled.is_enabled())
  assert_eq(enabled.options(), Some(options))

  let disabled = ExtensionSetting::disabled()
  assert_false(disabled.is_enabled())
  assert_eq(disabled.options(), None)
}

///|
test "app manifest stores windows and extension settings" {
  let main_window = WindowManifest::new("Main", 960, 720)
  let settings_window = AppWindowManifest::new(
    "settings",
    WindowManifest::new("Settings", 420, 320, size_hint=Fixed),
    File("settings.html"),
  )
  let manifest = AppManifest::new(
    main_window,
    Html("<html></html>"),
    debug=2,
    windows=[settings_window],
    extensions={
      "justjavac/lepus-fs": ExtensionSetting::enabled(
        options=Some(Json::object({ "scope": Json::string("read") })),
      ),
      "justjavac/lepus-dialog": ExtensionSetting::disabled(),
    },
  )

  assert_eq(manifest.window.title, "Main")
  assert_eq(manifest.window.width, 960)
  assert_eq(manifest.window.height, 720)
  assert_eq(manifest.window.size_hint, None)
  assert_eq(manifest.debug, 2)
  assert_eq(manifest.windows, [settings_window])
  assert_eq(
    manifest.extension_setting("justjavac/lepus-fs"),
    Some(
      ExtensionSetting::enabled(
        options=Some(Json::object({ "scope": Json::string("read") })),
      ),
    ),
  )
  assert_eq(
    manifest.extension_setting("justjavac/lepus-dialog"),
    Some(ExtensionSetting::disabled()),
  )
  assert_eq(manifest.extension_setting("justjavac/lepus-path"), None)
  assert_eq(manifest.extension_settings().length(), 2)
}

///|
test "app manifest supports asset-backed entries" {
  let manifest = AppManifest::new(
    WindowManifest::new("Assets", 960, 720),
    Asset("frontend/index.html"),
  )

  match manifest.entry {
    Asset(path) => assert_eq(path, "frontend/index.html")
    _ => abort("expected asset entry")
  }
}
