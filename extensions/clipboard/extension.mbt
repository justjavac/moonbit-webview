///|
let extension_id = "justjavac/lepus-clipboard"

///|
let extension_namespace = "clipboard"

///|
struct EmptyPayload {} derive(ToJson, FromJson, Debug, Eq)

///|
struct ReadTextReply {
  text : String?
} derive(ToJson, FromJson, Debug, Eq)

///|
struct WriteTextPayload {
  text : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct WriteTextReply {
  written : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ClipboardActivity {
  operation : String
  text_length : Int?
} derive(ToJson, FromJson, Debug, Eq)

///|
/// Verifies that the underlying clipboard package is available on this platform.
fn ensure_supported() -> Result[Unit, String] {
  @sys_clipboard.ensure_supported()
}

///|
/// Runs a clipboard operation only when the platform is supported.
fn[Reply] with_supported(
  callback : () -> Result[Reply, String],
) -> Result[Reply, String] {
  ensure_supported().bind(fn(_) { callback() })
}

///|
/// Returns the string length when clipboard text is present.
fn text_length(text : String?) -> Int? {
  match text {
    Some(text) => Some(text.length())
    None => None
  }
}

///|
/// Emits a clipboard activity event for JavaScript listeners.
fn emit_activity(
  extension : @core.ExtensionContext,
  operation : String,
  text_length? : Int? = None,
) -> Unit {
  extension.emit("activity", ClipboardActivity::{ operation, text_length })
}

///|
/// Builds the `clipboard` extension for direct installation.
/// Install it manually when trusted local content needs `readText` and
/// `writeText` without going through declarative app composition.
pub fn extension() -> @core.Extension {
  @core.Extension::new(extension_id, extension_namespace, fn(extension) {
    extension.op_result("readText", fn(_payload : EmptyPayload) {
      with_supported(fn() {
        @sys_clipboard.read_text().map(fn(text) {
          emit_activity(extension, "readText", text_length=text_length(text))
          ReadTextReply::{ text, }
        })
      })
    })

    extension.op_result("writeText", fn(payload : WriteTextPayload) {
      with_supported(fn() {
        @sys_clipboard.write_text(payload.text).map(fn(_) {
          emit_activity(
            extension,
            "writeText",
            text_length=Some(payload.text.length()),
          )
          WriteTextReply::{ written: true }
        })
      })
    })
  })
}

///|
/// Builds the declarative `clipboard` extension spec.
/// Use this when the extension should be registered in an app registry or
/// selected from manifest/catalog-driven tooling.
pub fn spec() -> @core.ExtensionSpec {
  @core.ExtensionSpec::new(extension_id, extension_namespace, fn(_context) {
    Ok(extension())
  })
}
