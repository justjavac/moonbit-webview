///|
/// Builds a minimal extension spec for app preparation tests.
fn stub_extension(
  id : String,
  js_namespace? : String? = None,
  dependencies? : Array[String] = [],
) -> @core.ExtensionSpec {
  let extension_namespace = match js_namespace {
    Some(value) => value
    None => id
  }
  @core.ExtensionSpec::new(
    id,
    extension_namespace,
    fn(_context) {
      Ok(@core.Extension::new(id, extension_namespace, fn(_context) {  }))
    },
    dependencies~,
  )
}

///|
/// Builds a representative manifest fixture for app preparation tests.
fn demo_manifest(
  extensions : Map[String, @manifest.ExtensionSetting],
) -> @manifest.AppManifest {
  @manifest.AppManifest::new(
    @manifest.WindowManifest::new("Planner", 960, 720),
    @manifest.AppEntry::Html("<html></html>"),
    debug=2,
    windows=[
      @manifest.AppWindowManifest::new(
        "settings",
        @manifest.WindowManifest::new("Settings", 420, 320),
        @manifest.AppEntry::File("settings.html"),
      ),
    ],
    extensions~,
  )
}

///|
/// Collects prepared extension ids in registration order for assertions.
fn prepared_extension_ids(prepared : PreparedApp) -> Array[String] {
  let ids : Array[String] = []
  for extension in prepared.prepared_extensions() {
    ids.push(extension.id())
  }
  ids
}

///|
test "prepare_app expands dependencies in deterministic order" {
  let registry = ExtensionRegistry::new()
    .register(stub_extension("justjavac/lepus-path", js_namespace=Some("path")))
    .register(
      stub_extension("justjavac/lepus-fs", js_namespace=Some("fs"), dependencies=[
        "justjavac/lepus-path",
      ]),
    )
    .register(
      stub_extension("justjavac/lepus-dialog", js_namespace=Some("dialog")),
    )

  let manifest = demo_manifest({
    "justjavac/lepus-fs": @manifest.ExtensionSetting::enabled(
      options=Some(Json::object({ "scope": Json::string("read") })),
    ),
    "justjavac/lepus-dialog": @manifest.ExtensionSetting::enabled(),
  })

  match prepare_app(manifest, registry, base_dir=Some("D:/workspace/app")) {
    Err(error) => abort(error)
    Ok(prepared) => {
      assert_eq(prepared_extension_ids(prepared), [
        "justjavac/lepus-path", "justjavac/lepus-fs", "justjavac/lepus-dialog",
      ])
      assert_eq(prepared.base_dir(), Some("D:/workspace/app"))
      let runtime_config = prepared.runtime_config()
      assert_eq(runtime_config.window.title, "Planner")
      assert_eq(runtime_config.window.width, 960)
      assert_eq(runtime_config.window.height, 720)
      assert_eq(runtime_config.debug, 2)
      assert_eq(runtime_config.windows.length(), 1)
      match runtime_config.entry {
        @wvrt.AppEntry::Html(html) => assert_eq(html, "<html></html>")
        _ => abort("expected html runtime entry")
      }
      match runtime_config.windows[0].entry {
        @wvrt.AppEntry::File(path) => assert_eq(path, "settings.html")
        _ => abort("expected file entry")
      }
    }
  }
}

///|
test "prepare_app preserves asset-backed runtime entries" {
  let registry = ExtensionRegistry::new()
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new("Asset Planner", 960, 720),
    @manifest.AppEntry::Asset("frontend/index.html"),
  )

  match prepare_app(manifest, registry, base_dir=Some("D:/workspace/app")) {
    Err(error) => abort(error)
    Ok(prepared) =>
      match prepared.runtime_config().entry {
        @wvrt.AppEntry::Asset(path) => assert_eq(path, "frontend/index.html")
        _ => abort("expected asset runtime entry")
      }
  }
}

///|
test "prepare_app rejects unknown manifest extension keys" {
  let registry = ExtensionRegistry::new()
  let manifest = demo_manifest({
    "justjavac/lepus-fs": @manifest.ExtensionSetting::enabled(),
  })
  match prepare_app(manifest, registry) {
    Err(error) => assert_eq(error, "unknown extension key: justjavac/lepus-fs")
    Ok(_) => abort("expected unknown extension error")
  }
}

///|
test "prepare_app rejects disabled dependencies" {
  let registry = ExtensionRegistry::new()
    .register(stub_extension("justjavac/lepus-path", js_namespace=Some("path")))
    .register(
      stub_extension("justjavac/lepus-fs", js_namespace=Some("fs"), dependencies=[
        "justjavac/lepus-path",
      ]),
    )

  let manifest = demo_manifest({
    "justjavac/lepus-path": @manifest.ExtensionSetting::disabled(),
    "justjavac/lepus-fs": @manifest.ExtensionSetting::enabled(),
  })

  match prepare_app(manifest, registry) {
    Err(error) =>
      assert_eq(
        error, "extension justjavac/lepus-fs requires disabled dependency justjavac/lepus-path",
      )
    Ok(_) => abort("expected disabled dependency error")
  }
}

///|
test "prepare_app rejects dependency cycles" {
  let registry = ExtensionRegistry::new()
    .register(
      stub_extension("vendor/alpha", js_namespace=Some("alpha"), dependencies=[
        "vendor/beta",
      ]),
    )
    .register(
      stub_extension("vendor/beta", js_namespace=Some("beta"), dependencies=[
        "vendor/alpha",
      ]),
    )

  let manifest = demo_manifest({
    "vendor/alpha": @manifest.ExtensionSetting::enabled(),
  })

  match prepare_app(manifest, registry) {
    Err(error) =>
      assert_eq(error, "extension dependency cycle detected at: vendor/alpha")
    Ok(_) => abort("expected dependency cycle error")
  }
}
