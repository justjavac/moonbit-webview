///|
let extension_id = "justjavac/lepus-fs"

///|
let extension_namespace = "fs"

///|
/// Builds the unrestricted `fs` extension for direct installation.
///
/// Install it with `@core.install_extension(webview, @fs.extension())` to expose
/// `window.__MoonBit__.fs`. Opened resources remember their resolved absolute path.
///
/// This extension intentionally exposes host filesystem access. Only install it
/// in webviews that load trusted/local content; do not combine it with
/// untrusted or remote HTML/JavaScript.
pub fn extension() -> @core.Extension {
  build_extension()
}

///|
/// Builds the declarative `fs` extension spec.
/// Register this spec when filesystem access should be linked through app
/// planning rather than installed ad hoc on one webview.
pub fn spec() -> @core.ExtensionSpec {
  @core.ExtensionSpec::new(extension_id, extension_namespace, fn(context) {
    ignore(context.base_dir())
    match context.options() {
      None => Ok(extension())
      Some(_) => Err("fs extension options are not supported")
    }
  })
}

///|
/// Creates the runtime `fs` extension with shared handle and path tables.
fn build_extension() -> @core.Extension {
  let handles : @core.ResourceTable[MemoryFileHandle] = @core.ResourceTable::new()
  let paths : Map[Int, String] = {}

  @core.Extension::new(
    extension_id,
    extension_namespace,
    fn(extension) {
      register_file_text_ops(extension)
      register_path_ops(extension)
      register_stream_ops(extension, handles, paths)
    },
    on_destroy=fn(_extension) { close_all_open_files(handles, paths) },
    scripts=[fs_helper_script()],
  )
}
