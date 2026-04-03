///|
/// Builds the unrestricted `fs` extension for new application code.
///
/// Install it with `@runtime.install_extension(webview, @fs.extension())` to expose
/// `window.__MoonBit__.fs`. Opened resources remember their resolved absolute path.
///
/// This extension intentionally exposes host filesystem access. Only install it
/// in webviews that load trusted/local content; do not combine it with
/// untrusted or remote HTML/JavaScript.
pub fn extension() -> @runtime.Extension {
  build_extension()
}

///|
pub fn app_extension() -> @app.AppExtension {
  @app.AppExtension::new("fs", fn(context) {
    ignore(context.base_dir())
    match context.options() {
      None => Ok(extension())
      Some(_) => Err("fs extension options are not supported")
    }
  })
}

///|
fn build_extension() -> @runtime.Extension {
  let handles : @runtime.ResourceTable[MemoryFileHandle] = @runtime.ResourceTable::new()
  let paths : Map[Int, String] = {}

  @runtime.Extension::new(
    "fs",
    fn(extension) {
      register_file_text_ops(extension)
      register_path_ops(extension)
      register_stream_ops(extension, handles, paths)
    },
    on_destroy=fn(_extension) { close_all_open_files(handles, paths) },
    helper_script=fs_helper_script,
  )
}

///|
test "fs app extension rejects unsupported options" {
  match
    app_extension().build_extension(
      @app.AppExtensionContext::new(
        options=Some(Json::object({ "deprecated": Json::boolean(true) })),
      ),
    ) {
    Ok(_) => abort("expected fs extension options rejection")
    Err(error) =>
      assert_eq(
        error,
        "fs extension options are not supported",
      )
  }
}
