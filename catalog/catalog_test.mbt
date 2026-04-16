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
/// Builds one minimal descriptor for link-planning tests.
fn stub_descriptor(
  id : String,
  js_namespace : String,
  dependencies? : Array[String] = [],
  package_path? : String = "extensions/" + js_namespace,
  spec_symbol? : String = "spec",
) -> ExtensionDescriptor {
  ExtensionDescriptor::new(
    2,
    id,
    "0.1.0",
    id,
    id + " extension",
    js_namespace,
    id,
    package_path,
    spec_symbol,
    ["windows"],
    dependencies,
    [id + ".demo"],
    "./options.schema.json",
    package_path,
  )
}

///|
/// Resolves a catalog test fixture path from either module-local or workspace layout.
fn catalog_test_path(path : String) -> String {
  resolve_fixture_path([path, "catalog/" + path])
}

///|
/// Resolves the root directory of one built-in extension fixture for tests.
fn builtin_extension_root(name : String) -> String {
  resolve_fixture_path(["../extensions/" + name, "extensions/" + name])
}

///|
test "discover_extension_descriptor_files can target one extension package" {
  let descriptor_paths = match
    discover_extension_descriptor_files([builtin_extension_root("path")]) {
    Ok(paths) => paths
    Err(error) => abort(error)
  }

  assert_eq(descriptor_paths.length(), 1)
  assert_true(descriptor_paths[0].has_suffix("extension.json"))

  let catalog = match
    load_extension_catalog_from_search_roots([builtin_extension_root("path")]) {
    Ok(catalog) => catalog
    Err(error) => abort(error)
  }

  assert_eq(catalog.descriptor_ids(), ["justjavac/lepus-path"])
}

///|
test "load_extension_catalog_from_search_roots treats built-in and external roots the same" {
  let catalog = match
    load_extension_catalog_from_search_roots([
      builtin_extension_root("path"),
      catalog_test_path("testdata/vendor_extensions"),
    ]) {
    Ok(catalog) => catalog
    Err(error) => abort(error)
  }

  let ids = catalog.descriptor_ids()
  ids.sort()
  assert_eq(ids, ["vendor/base", "vendor/echo", "justjavac/lepus-path"])

  let schema = match catalog.load_schema("vendor/echo") {
    Ok(schema) => schema
    Err(error) => abort(error)
  }

  assert_eq(schema.descriptor_id(), "vendor/echo")
  assert_true(schema.path().has_suffix("options.schema.json"))
  match schema.json() {
    Object(object) =>
      assert_eq(object.get("title"), Some(Json::string("vendor echo options")))
    _ => abort("expected schema object")
  }
}

///|
test "build_extension_link_plan expands metadata dependencies in order" {
  let catalog = match
    ExtensionCatalog::from_descriptors([
      stub_descriptor("justjavac/lepus-path", "path"),
      stub_descriptor("justjavac/lepus-fs", "fs", dependencies=[
        "justjavac/lepus-path",
      ]),
      stub_descriptor("justjavac/lepus-dialog", "dialog"),
    ]) {
    Ok(catalog) => catalog
    Err(error) => abort(error)
  }

  let plan = match
    build_extension_link_plan(catalog, [
      "justjavac/lepus-fs", "justjavac/lepus-dialog",
    ]) {
    Ok(plan) => plan
    Err(error) => abort(error)
  }

  assert_eq(plan.extension_ids(), [
    "justjavac/lepus-path", "justjavac/lepus-fs", "justjavac/lepus-dialog",
  ])
  assert_eq(plan.inputs()[0].package_path(), "extensions/path")
  assert_eq(plan.inputs()[1].spec_symbol(), "spec")
}

///|
test "build_extension_link_plan rejects dependency cycles" {
  let catalog = match
    ExtensionCatalog::from_descriptors([
      stub_descriptor("vendor/alpha", "alpha", dependencies=["vendor/beta"]),
      stub_descriptor("vendor/beta", "beta", dependencies=["vendor/alpha"]),
    ]) {
    Ok(catalog) => catalog
    Err(error) => abort(error)
  }

  match build_extension_link_plan(catalog, ["vendor/alpha"]) {
    Ok(_) => abort("expected dependency cycle error")
    Err(error) =>
      assert_true(error.contains("extension dependency cycle detected"))
  }
}
