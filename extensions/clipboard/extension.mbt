///|
struct EmptyPayload {} derive(ToJson, FromJson, Show, Eq)

///|
struct ReadTextReply {
  text : String?
} derive(ToJson, FromJson, Show, Eq)

///|
struct WriteTextPayload {
  text : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct WriteTextReply {
  written : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct ClipboardActivity {
  operation : String
  text_length : Int?
} derive(ToJson, FromJson, Show, Eq)

///|
fn ensure_supported() -> Result[Unit, String] {
  @sys_clipboard.ensure_supported()
}

///|
fn[Reply] with_supported(callback : () -> Result[Reply, String]) -> Result[
  Reply,
  String,
] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) => callback()
  }
}

///|
fn text_length(text : String?) -> Int? {
  match text {
    Some(text) => Some(text.length())
    None => None
  }
}

///|
fn emit_activity(
  extension : @runtime.ExtensionContext,
  operation : String,
  text_length? : Int? = None,
) -> Unit {
  extension.emit("activity", ClipboardActivity::{ operation, text_length })
}

///|
/// Builds the `clipboard` extension for new application code.
pub fn extension() -> @runtime.Extension {
  @runtime.Extension::new("clipboard", fn(extension) {
    extension.op_result("readText", fn(_payload : EmptyPayload) {
      with_supported(fn() {
        match @sys_clipboard.read_text() {
          Err(error) => Err(error)
          Ok(text) => {
            emit_activity(extension, "readText", text_length=text_length(text))
            Ok(ReadTextReply::{ text, })
          }
        }
      })
    })

    extension.op_result("writeText", fn(payload : WriteTextPayload) {
      with_supported(fn() {
        match @sys_clipboard.write_text(payload.text) {
          Err(error) => Err(error)
          Ok(_) => {
            emit_activity(
              extension,
              "writeText",
              text_length=Some(payload.text.length()),
            )
            Ok(WriteTextReply::{ written: true })
          }
        }
      })
    })
  })
}

///|
pub fn app_extension() -> @app.AppExtension {
  @app.AppExtension::new("clipboard", fn(_context) { Ok(extension()) })
}
