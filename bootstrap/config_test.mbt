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
/// Normalizes test paths so assertions stay stable across Windows and Unix separators.
fn normalize_test_slashes(path : String) -> String {
  let builder = StringBuilder::new(size_hint=path.length())
  for _, ch in path {
    builder.write_char(if ch == '\\' { '/' } else { ch })
  }
  builder.to_string()
}

///|
/// Resolves one bootstrap manifest fixture path from either module-local or workspace layout.
fn manifest_test_path(name : String) -> String {
  resolve_fixture_path(["testdata/" + name, "bootstrap/testdata/" + name])
}

///|
/// Returns the detached JSON value used by document-editing assertions.
fn manifest_document_json(document : AppManifestDocument) -> Json {
  document.to_json()
}

///|
test "load_app_manifest_from_json applies defaults" {
  let result = load_app_manifest_from_json(
    (
      #|{
      #|  "window": {
      #|    "title": "JSON Runtime",
      #|    "width": 840,
      #|    "height": 600
      #|  },
      #|  "entry": {
      #|    "kind": "html",
      #|    "value": "<html></html>"
      #|  }
      #|}
    ),
  )
  match result {
    Err(error) => abort(error)
    Ok(loaded) => {
      let manifest = loaded.manifest()
      assert_eq(manifest.window.title, "JSON Runtime")
      assert_eq(manifest.window.width, 840)
      assert_eq(manifest.window.height, 600)
      assert_eq(manifest.window.size_hint, @manifest.WindowSizeHint::None)
      assert_eq(manifest.debug, 0)
      assert_eq(manifest.windows.length(), 0)
      assert_eq(loaded.base_dir(), None)
      match manifest.entry {
        Html(html) => assert_eq(html, "<html></html>")
        _ => abort("expected html entry")
      }
    }
  }
}

///|
test "load_app_manifest_document_from_file rebases file entry and preserves settings" {
  let result = load_app_manifest_document_from_file(
    manifest_test_path("app.json"),
  )
  match result {
    Err(error) => abort(error)
    Ok(document) => {
      let loaded = document.loaded_manifest()
      let manifest = loaded.manifest()
      match manifest.entry {
        File(path) =>
          assert_true(
            normalize_test_slashes(path).has_suffix("testdata/app.html"),
          )
        _ => abort("expected file entry")
      }
      match loaded.base_dir() {
        None => abort("expected manifest base dir")
        Some(base_dir) =>
          assert_true(
            normalize_test_slashes(base_dir).has_suffix("bootstrap/testdata"),
          )
      }
      assert_eq(
        document.extension_setting("justjavac/lepus-fs"),
        Some(
          @manifest.ExtensionSetting::enabled(options=Some(Json::object({}))),
        ),
      )
      assert_eq(
        document.extension_setting("justjavac/lepus-path"),
        Some(
          @manifest.ExtensionSetting::enabled(options=Some(Json::object({}))),
        ),
      )
      assert_eq(
        document.extension_setting("justjavac/lepus-notification"),
        None,
      )
    }
  }
}

///|
test "load_app_manifest_from_json rejects unknown entry kinds" {
  let result = load_app_manifest_from_json(
    (
      #|{
      #|  "window": {
      #|    "title": "Broken",
      #|    "width": 800,
      #|    "height": 600
      #|  },
      #|  "entry": {
      #|    "kind": "markdown",
      #|    "value": "README.md"
      #|  }
      #|}
    ),
  )
  match result {
    Ok(_) => abort("expected entry kind validation failure")
    Err(error) => assert_eq(error, "unsupported app entry kind: markdown")
  }
}

///|
test "load_app_manifest_from_json parses additional windows" {
  let result = load_app_manifest_from_json(
    (
      #|{
      #|  "window": {
      #|    "title": "Main",
      #|    "width": 800,
      #|    "height": 600
      #|  },
      #|  "entry": {
      #|    "kind": "html",
      #|    "value": "<html>Main</html>"
      #|  },
      #|  "windows": [
      #|    {
      #|      "id": "docs",
      #|      "window": {
      #|        "title": "Docs",
      #|        "width": 640,
      #|        "height": 480,
      #|        "size_hint": "fixed"
      #|      },
      #|      "entry": {
      #|        "kind": "url",
      #|        "value": "https://example.com/docs"
      #|      }
      #|    }
      #|  ]
      #|}
    ),
  )
  match result {
    Err(error) => abort(error)
    Ok(loaded) => {
      let manifest = loaded.manifest()
      assert_eq(manifest.windows.length(), 1)
      let window = manifest.windows[0]
      assert_eq(window.id, "docs")
      assert_eq(window.window.title, "Docs")
      assert_eq(window.window.size_hint, @manifest.WindowSizeHint::Fixed)
      match window.entry {
        Url(url) => assert_eq(url, "https://example.com/docs")
        _ => abort("expected url entry")
      }
    }
  }
}

///|
test "load_app_manifest_document_from_file rebases asset entry" {
  let result = load_app_manifest_document_from_file(
    manifest_test_path("asset_app.json"),
  )
  match result {
    Err(error) => abort(error)
    Ok(document) =>
      match document.manifest().entry {
        Asset(path) =>
          assert_true(
            normalize_test_slashes(path).has_suffix(
              "bootstrap/testdata/frontend/index.html",
            ),
          )
        _ => abort("expected asset entry")
      }
  }
}

///|
test "load_app_manifest_from_json rejects legacy permissions field" {
  let result = load_app_manifest_from_json(
    (
      #|{
      #|  "window": {
      #|    "title": "Legacy",
      #|    "width": 800,
      #|    "height": 600
      #|  },
      #|  "entry": {
      #|    "kind": "html",
      #|    "value": "<html></html>"
      #|  },
      #|  "permissions": {
      #|    "justjavac/lepus-notification": false
      #|  }
      #|}
    ),
  )
  match result {
    Ok(_) => abort("expected legacy permissions rejection")
    Err(error) =>
      assert_eq(
        error, "app manifest.permissions is no longer supported; remove it",
      )
  }
}

///|
test "load_app_manifest_document preserves extension settings" {
  let document_result = load_app_manifest_document_from_json(
    (
      #|{
      #|  "window": {
      #|    "title": "Document",
      #|    "width": 800,
      #|    "height": 600
      #|  },
      #|  "entry": {
      #|    "kind": "html",
      #|    "value": "<html></html>"
      #|  },
      #|  "extensions": {
      #|    "justjavac/lepus-path": true,
      #|    "vendor/echo": {
      #|      "message": "hi"
      #|    },
      #|    "justjavac/lepus-tray": false
      #|  }
      #|}
    ),
  )
  match document_result {
    Err(error) => abort(error)
    Ok(document) => {
      assert_eq(
        document.extension_setting("justjavac/lepus-path"),
        Some(@manifest.ExtensionSetting::enabled()),
      )
      assert_eq(
        document.extension_setting("vendor/echo"),
        Some(
          @manifest.ExtensionSetting::enabled(
            options=Some(Json::object({ "message": Json::string("hi") })),
          ),
        ),
      )
      assert_eq(
        document.extension_setting("justjavac/lepus-tray"),
        Some(@manifest.ExtensionSetting::disabled()),
      )
      assert_eq(document.extension_settings().length(), 3)
    }
  }
}

///|
test "app manifest document updates keep previous documents detached" {
  let document = match
    load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Document",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html></html>"
        #|  }
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }
  let with_extension = match
    document.enable_extension(
      "justjavac/lepus-notification",
      options=Some(Json::object({ "level": Json::string("info") })),
    ) {
    Ok(updated_document) => updated_document
    Err(error) => abort(error)
  }

  assert_eq(document.extension_setting("justjavac/lepus-notification"), None)
  assert_eq(
    with_extension.extension_setting("justjavac/lepus-notification"),
    Some(
      @manifest.ExtensionSetting::enabled(
        options=Some(Json::object({ "level": Json::string("info") })),
      ),
    ),
  )

  match manifest_document_json(document) {
    Object(object) => assert_eq(object.get("extensions"), None)
    _ => abort("expected manifest object")
  }
  match manifest_document_json(with_extension) {
    Object(object) =>
      match object.get("extensions") {
        Some(Object(extension_object)) =>
          assert_eq(
            extension_object.get("justjavac/lepus-notification"),
            Some(Json::object({ "level": Json::string("info") })),
          )
        _ => abort("expected extensions object")
      }
    _ => abort("expected manifest object")
  }
}

///|
test "app manifest document remove_extension_setting clears empty object" {
  let document = match
    load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Document",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html></html>"
        #|  },
        #|  "extensions": {
        #|    "justjavac/lepus-notification": {}
        #|  }
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }
  let updated = match
    document.remove_extension_setting("justjavac/lepus-notification") {
    Ok(updated) => updated
    Err(error) => abort(error)
  }

  assert_eq(
    document.extension_setting("justjavac/lepus-notification"),
    Some(@manifest.ExtensionSetting::enabled(options=Some(Json::object({})))),
  )
  assert_eq(updated.extension_setting("justjavac/lepus-notification"), None)
  match manifest_document_json(updated) {
    Object(object) => assert_eq(object.get("extensions"), None)
    _ => abort("expected manifest object")
  }
}

///|
test "app manifest document can replace window entry and debug" {
  let document = match
    load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Main",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html>Main</html>"
        #|  }
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }
  let updated = match
    document.set_window(
      @manifest.WindowManifest::new(
        "Settings",
        420,
        320,
        size_hint=@manifest.WindowSizeHint::Fixed,
      ),
    ) {
    Ok(updated) => updated
    Err(error) => abort(error)
  }
  let updated = match
    updated.set_entry(@manifest.AppEntry::File("settings.html")) {
    Ok(updated) => updated
    Err(error) => abort(error)
  }
  let updated = match updated.set_debug(2) {
    Ok(updated) => updated
    Err(error) => abort(error)
  }

  assert_eq(document.manifest().window.title, "Main")
  assert_eq(document.manifest().debug, 0)

  let manifest = updated.manifest()
  assert_eq(manifest.window.title, "Settings")
  assert_eq(manifest.window.width, 420)
  assert_eq(manifest.window.height, 320)
  assert_eq(manifest.window.size_hint, @manifest.WindowSizeHint::Fixed)
  assert_eq(manifest.debug, 2)
  match manifest.entry {
    File(path) => assert_eq(path, "settings.html")
    _ => abort("expected file entry")
  }

  match manifest_document_json(updated) {
    Object(object) => {
      match object.get("window") {
        Some(Object(window_object)) => {
          assert_eq(window_object.get("title"), Some(Json::string("Settings")))
          assert_eq(window_object.get("width"), Some(ToJson::to_json(420)))
          assert_eq(window_object.get("height"), Some(ToJson::to_json(320)))
          assert_eq(window_object.get("size_hint"), Some(Json::string("fixed")))
        }
        _ => abort("expected window object")
      }
      match object.get("entry") {
        Some(Object(entry_object)) => {
          assert_eq(entry_object.get("kind"), Some(Json::string("file")))
          assert_eq(
            entry_object.get("value"),
            Some(Json::string("settings.html")),
          )
        }
        _ => abort("expected entry object")
      }
      assert_eq(object.get("debug"), Some(ToJson::to_json(2)))
    }
    _ => abort("expected manifest object")
  }
}

///|
test "app manifest document persists asset entry kind" {
  let document = match
    load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Main",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html>Main</html>"
        #|  }
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }
  let updated = match
    document.set_entry(@manifest.AppEntry::Asset("frontend/index.html")) {
    Ok(updated) => updated
    Err(error) => abort(error)
  }

  match updated.manifest().entry {
    Asset(path) => assert_eq(path, "frontend/index.html")
    _ => abort("expected asset entry")
  }

  match manifest_document_json(updated) {
    Object(object) =>
      match object.get("entry") {
        Some(Object(entry_object)) => {
          assert_eq(entry_object.get("kind"), Some(Json::string("asset")))
          assert_eq(
            entry_object.get("value"),
            Some(Json::string("frontend/index.html")),
          )
        }
        _ => abort("expected entry object")
      }
    _ => abort("expected manifest object")
  }
}

///|
test "app manifest document can upsert and remove secondary windows" {
  let document = match
    load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Main",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html>Main</html>"
        #|  },
        #|  "windows": [
        #|    {
        #|      "id": "docs",
        #|      "window": {
        #|        "title": "Docs",
        #|        "width": 500,
        #|        "height": 400
        #|      },
        #|      "entry": {
        #|        "kind": "url",
        #|        "value": "https://example.com/docs"
        #|      }
        #|    }
        #|  ]
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }
  let with_settings = match
    document.upsert_window(
      @manifest.AppWindowManifest::new(
        "settings",
        @manifest.WindowManifest::new(
          "Settings",
          420,
          320,
          size_hint=@manifest.WindowSizeHint::Fixed,
        ),
        @manifest.AppEntry::File("settings.html"),
      ),
    ) {
    Ok(updated) => updated
    Err(error) => abort(error)
  }
  let replaced_settings = match
    with_settings.upsert_window(
      @manifest.AppWindowManifest::new(
        "settings",
        @manifest.WindowManifest::new("Settings v2", 640, 480),
        @manifest.AppEntry::Html("<html>Settings</html>"),
      ),
    ) {
    Ok(updated) => updated
    Err(error) => abort(error)
  }
  let without_docs = match replaced_settings.remove_window("docs") {
    Ok(updated) => updated
    Err(error) => abort(error)
  }
  let without_settings = match without_docs.remove_window("settings") {
    Ok(updated) => updated
    Err(error) => abort(error)
  }

  assert_eq(document.manifest().windows.length(), 1)
  assert_eq(with_settings.manifest().windows.length(), 2)
  assert_eq(replaced_settings.manifest().windows.length(), 2)
  assert_eq(without_docs.manifest().windows.length(), 1)
  assert_eq(without_settings.manifest().windows.length(), 0)

  let settings_window = replaced_settings.manifest().windows[1]
  assert_eq(settings_window.id, "settings")
  assert_eq(settings_window.window.title, "Settings v2")
  assert_eq(settings_window.window.width, 640)
  match settings_window.entry {
    Html(html) => assert_eq(html, "<html>Settings</html>")
    _ => abort("expected html settings entry")
  }

  match manifest_document_json(without_settings) {
    Object(object) => assert_eq(object.get("windows"), None)
    _ => abort("expected manifest object")
  }
}

///|
test "app manifest document to_json returns a detached copy" {
  let document = match
    load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Detached",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html></html>"
        #|  }
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }

  match manifest_document_json(document) {
    Object(object) => object["debug"] = ToJson::to_json(99)
    _ => abort("expected manifest object")
  }

  match manifest_document_json(document) {
    Object(object) => assert_eq(object.get("debug"), None)
    _ => abort("expected manifest object")
  }
}

///|
test "load_app_manifest_from_json accepts boolean extension settings" {
  let result = load_app_manifest_from_json(
    (
      #|{
      #|  "window": {
      #|    "title": "Boolean Extensions",
      #|    "width": 800,
      #|    "height": 600
      #|  },
      #|  "entry": {
      #|    "kind": "html",
      #|    "value": "<html></html>"
      #|  },
      #|  "extensions": {
      #|    "justjavac/lepus-fs": true,
      #|    "justjavac/lepus-tray": false
      #|  }
      #|}
    ),
  )
  match result {
    Err(error) => abort(error)
    Ok(loaded) => {
      let manifest = loaded.manifest()
      assert_eq(
        manifest.extension_setting("justjavac/lepus-fs"),
        Some(@manifest.ExtensionSetting::enabled()),
      )
      assert_eq(
        manifest.extension_setting("justjavac/lepus-tray"),
        Some(@manifest.ExtensionSetting::disabled()),
      )
    }
  }
}

///|
test "load_app_manifest_from_json rejects invalid extension setting values" {
  let result = load_app_manifest_from_json(
    (
      #|{
      #|  "window": {
      #|    "title": "Broken",
      #|    "width": 800,
      #|    "height": 600
      #|  },
      #|  "entry": {
      #|    "kind": "html",
      #|    "value": "<html></html>"
      #|  },
      #|  "extensions": {
      #|    "justjavac/lepus-fs": "yes"
      #|  }
      #|}
    ),
  )
  match result {
    Ok(_) => abort("expected extension setting validation failure")
    Err(error) =>
      assert_eq(
        error, "expected boolean or object for app manifest.extensions.justjavac/lepus-fs",
      )
  }
}
