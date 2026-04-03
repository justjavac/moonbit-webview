///|
fn normalize_test_slashes(path : String) -> String {
  let builder = StringBuilder::new(size_hint=path.length())
  for _, ch in path {
    builder.write_char(if ch == '\\' { '/' } else { ch })
  }
  builder.to_string()
}

///|
fn config_document_json(document : AppConfigDocument) -> Json {
  document.to_json()
}

///|
test "load_app_config_from_json applies defaults" {
  let result = load_app_config_from_json(
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
    Ok(config) => {
      assert_eq(config.window.title, "JSON Runtime")
      assert_eq(config.window.width, 840)
      assert_eq(config.window.height, 600)
      match config.window.size_hint {
        @webview.SizeHint::None => ()
        _ => abort("expected default size hint")
      }
      assert_eq(config.debug, 0)
      assert_eq(config.windows.length(), 0)
      assert_eq(config.base_dir, None)
      match config.entry {
        Html(html) => assert_eq(html, "<html></html>")
        _ => abort("expected html entry")
      }
    }
  }
}

///|
test "load_app_config_document_from_file rebases file entry and preserves options" {
  let result = load_app_config_document_from_file("testdata/app.json")
  match result {
    Err(error) => abort(error)
    Ok(document) => {
      let config = document.config()
      match config.entry {
        File(path) =>
          assert_true(
            normalize_test_slashes(path).has_suffix("testdata/app.html"),
          )
        _ => abort("expected file entry")
      }
      match config.base_dir {
        None => abort("expected config base dir")
        Some(base_dir) =>
          assert_true(
            normalize_test_slashes(base_dir).has_suffix("bootstrap/testdata"),
          )
      }
      assert_eq(document.extension_options("fs"), Some(Json::object({})))
      assert_eq(document.extension_options("path"), Some(Json::object({})))
      assert_eq(document.extension_options("notification"), None)
    }
  }
}

///|
test "load_app_config_from_json rejects unknown entry kinds" {
  let result = load_app_config_from_json(
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
test "load_app_config_from_json parses additional windows" {
  let result = load_app_config_from_json(
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
    Ok(config) => {
      assert_eq(config.windows.length(), 1)
      let window = config.windows[0]
      assert_eq(window.id, "docs")
      assert_eq(window.window.title, "Docs")
      match window.window.size_hint {
        @webview.SizeHint::Fixed => ()
        _ => abort("expected fixed size hint")
      }
      match window.entry {
        Url(url) => assert_eq(url, "https://example.com/docs")
        _ => abort("expected url entry")
      }
    }
  }
}

///|
test "load_app_config_from_json rejects legacy permissions field" {
  let result = load_app_config_from_json(
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
      #|    "notification": false
      #|  }
      #|}
    ),
  )
  match result {
    Ok(_) => abort("expected legacy permissions rejection")
    Err(error) =>
      assert_eq(
        error,
        "app config.permissions is no longer supported; remove it",
      )
  }
}

///|
test "load_app_config_document preserves extension option objects" {
  let document_result = load_app_config_document_from_json(
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
      #|    "path": {},
      #|    "echo": {
      #|      "message": "hi"
      #|    }
      #|  }
      #|}
    ),
  )
  match document_result {
    Err(error) => abort(error)
    Ok(document) => {
      assert_eq(document.extension_options("path"), Some(Json::object({})))
      assert_eq(
        document.extension_options("echo"),
        Some(Json::object({ "message": Json::string("hi") })),
      )
      assert_eq(document.extension_option_entries().length(), 2)
      match config_document_json(document) {
        Object(object) =>
          match object.get("extensions") {
            Some(Object(extension_object)) => {
              assert_eq(extension_object.get("path"), Some(Json::object({})))
              assert_eq(
                extension_object.get("echo"),
                Some(Json::object({ "message": Json::string("hi") })),
              )
            }
            _ => abort("expected extensions object")
          }
        _ => abort("expected config object")
      }
    }
  }
}

///|
test "app config document updates keep previous documents detached" {
  let document = match load_app_config_document_from_json(
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
    document.set_extension_options(
      "notification",
      Json::object({ "level": Json::string("info") }),
    ) {
    Ok(updated_document) => updated_document
    Err(error) => abort(error)
  }

  assert_eq(document.extension_options("notification"), None)
  assert_eq(
    with_extension.extension_options("notification"),
    Some(Json::object({ "level": Json::string("info") })),
  )

  match config_document_json(document) {
    Object(object) => assert_eq(object.get("extensions"), None)
    _ => abort("expected config object")
  }
  match config_document_json(with_extension) {
    Object(object) =>
      match object.get("extensions") {
        Some(Object(extension_object)) =>
          assert_eq(extension_object.get("notification"), Some(Json::object({
            "level": Json::string("info"),
          })))
        _ => abort("expected extensions object")
      }
    _ => abort("expected config object")
  }
}

///|
test "app config document remove_extension_options clears empty object" {
  let document = match load_app_config_document_from_json(
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
      #|    "notification": {}
      #|  }
      #|}
    ),
  ) {
    Ok(document) => document
    Err(error) => abort(error)
  }
  let updated = match document.remove_extension_options("notification") {
    Ok(updated) => updated
    Err(error) => abort(error)
  }

  assert_eq(document.extension_options("notification"), Some(Json::object({})))
  assert_eq(updated.extension_options("notification"), None)
  match config_document_json(updated) {
    Object(object) => assert_eq(object.get("extensions"), None)
    _ => abort("expected config object")
  }
}

///|
test "app config document to_json returns a detached copy" {
  let document = match load_app_config_document_from_json(
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

  match config_document_json(document) {
    Object(object) => object["debug"] = Json::number(99)
    _ => abort("expected config object")
  }

  match config_document_json(document) {
    Object(object) => assert_eq(object.get("debug"), None)
    _ => abort("expected config object")
  }
}

///|
test "load_app_config_from_json rejects non-object extension options" {
  let result = load_app_config_from_json(
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
      #|    "fs": true
      #|  }
      #|}
    ),
  )
  match result {
    Ok(_) => abort("expected extension options validation failure")
    Err(error) => assert_eq(error, "expected object for app config.extensions.fs")
  }
}
