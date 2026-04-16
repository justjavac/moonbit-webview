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
/// Resolves the root directory of one built-in extension fixture for tooling tests.
fn builtin_extension_root(name : String) -> String {
  resolve_fixture_path(["../extensions/" + name, "extensions/" + name])
}

///|
/// Resolves the third-party vendor extension fixture root used by tooling tests.
fn vendor_extension_root() -> String {
  resolve_fixture_path([
    "../catalog/testdata/vendor_extensions", "catalog/testdata/vendor_extensions",
  ])
}

///|
test "query_extension_catalog lists built-in and third-party extensions" {
  let summaries = match
    query_extension_catalog([
      builtin_extension_root("path"),
      vendor_extension_root(),
    ]) {
    Ok(summaries) => summaries
    Err(error) => abort(error)
  }

  let ids : Array[String] = []
  for summary in summaries {
    ids.push(summary.id)
  }
  ids.sort()
  assert_eq(ids, ["vendor/base", "vendor/echo", "justjavac/lepus-path"])

  let json = match
    query_extension_catalog_json([
      builtin_extension_root("path"),
      vendor_extension_root(),
    ]) {
    Ok(json) => json
    Err(error) => abort(error)
  }
  match json {
    Array(items) => assert_eq(items.length(), 3)
    _ => abort("expected catalog query array")
  }
}

///|
test "declared_extension_ids keeps manifest order and filters disabled entries" {
  let document = match
    @bootstrap.load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Tooling",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html></html>"
        #|  },
        #|  "extensions": {
        #|    "vendor/echo": {},
        #|    "justjavac/lepus-tray": false,
        #|    "justjavac/lepus-path": true
        #|  }
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }

  assert_eq(declared_extension_ids(document), [
    "vendor/echo", "justjavac/lepus-path",
  ])
  assert_eq(declared_extension_ids(document, enabled_only=false), [
    "vendor/echo", "justjavac/lepus-tray", "justjavac/lepus-path",
  ])
}

///|
test "generate_registry_module_from_document emits explicit imports and dependency registrations" {
  let document = match
    @bootstrap.load_app_manifest_document_from_json(
      (
        #|{
        #|  "window": {
        #|    "title": "Tooling",
        #|    "width": 800,
        #|    "height": 600
        #|  },
        #|  "entry": {
        #|    "kind": "html",
        #|    "value": "<html></html>"
        #|  },
        #|  "extensions": {
        #|    "vendor/echo": {}
        #|  }
        #|}
      ),
    ) {
    Ok(document) => document
    Err(error) => abort(error)
  }

  let generated = match
    generate_registry_module_from_document(
      document,
      [vendor_extension_root()],
      function_name="build_vendor_registry",
    ) {
    Ok(generated) => generated
    Err(error) => abort(error)
  }

  assert_eq(generated.function_name(), "build_vendor_registry")
  assert_eq(generated.recommended_file_name(), "build_vendor_registry.mbt")
  assert_eq(generated.extension_ids(), ["vendor/base", "vendor/echo"])
  assert_true(
    generated
    .moon_pkg_import_block()
    .contains(
      "\"vendor/extensions/vendor_base\" @ext_vendor_extensions_vendor_base",
    ),
  )
  assert_true(
    generated
    .moon_pkg_import_block()
    .contains(
      "\"vendor/extensions/vendor_echo\" @ext_vendor_extensions_vendor_echo",
    ),
  )
  assert_true(
    generated
    .source()
    .contains(
      "let _ = registry.register(@ext_vendor_extensions_vendor_base.spec())",
    ),
  )
  assert_true(
    generated
    .source()
    .contains(
      "let _ = registry.register(@ext_vendor_extensions_vendor_echo.spec())",
    ),
  )
}

///|
test "generate_registry_module_from_search_roots rejects invalid function names" {
  match
    generate_registry_module_from_search_roots(
      [vendor_extension_root()],
      ["vendor/echo"],
      function_name="BuildVendorRegistry",
    ) {
    Ok(_) => abort("expected invalid function name error")
    Err(error) =>
      assert_true(
        error.contains(
          "generated registry function name must start with a lowercase letter or _",
        ) ||
        error.contains(
          "generated registry function name must use only lowercase letters, digits, or _",
        ),
      )
  }
}
