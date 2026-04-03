///|
struct MessagePayload {
  message : String
  title : String?
  level : String?
} derive(ToJson, FromJson, Show, Eq)

///|
struct MessageReply {
  acknowledged : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct ConfirmReply {
  confirmed : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct FileDialogPayload {
  title : String?
  path : String?
} derive(ToJson, FromJson, Show, Eq)

///|
struct FileDialogReply {
  path : String?
} derive(ToJson, FromJson, Show, Eq)

///|
struct DialogActivity {
  operation : String
  path : String?
  level : String?
} derive(ToJson, FromJson, Show, Eq)

///|
extern "C" fn is_windows_ffi() -> Bool = "extensions_dialog_is_windows"

///|
#borrow(title, message)
extern "C" fn message_dialog_ffi(
  window : Int64,
  title : Bytes,
  message : Bytes,
  level : Int,
) -> Int = "extensions_dialog_message"

///|
#borrow(title, message)
extern "C" fn confirm_dialog_ffi(
  window : Int64,
  title : Bytes,
  message : Bytes,
  level : Int,
) -> Bool = "extensions_dialog_confirm"

///|
#borrow(title, path)
extern "C" fn open_file_dialog_ffi(
  window : Int64,
  title : Bytes,
  path : Bytes,
) -> Bytes = "extensions_dialog_open_file"

///|
#borrow(title, path)
extern "C" fn save_file_dialog_ffi(
  window : Int64,
  title : Bytes,
  path : Bytes,
) -> Bytes = "extensions_dialog_save_file"

///|
fn ensure_supported() -> Result[Unit, String] {
  if is_windows_ffi() {
    Ok(())
  } else {
    Err("dialog extension currently supports Windows native builds only")
  }
}

///|
fn[Reply] with_supported(
  callback : () -> Result[Reply, String],
) -> Result[Reply, String] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) => callback()
  }
}

///|
fn to_wstr(value : String?) -> Bytes {
  match value {
    Some(value) => @ffi.to_wstr(value)
    None => @ffi.to_wstr("")
  }
}

///|
fn message_title_bytes(payload : MessagePayload) -> Bytes {
  to_wstr(payload.title)
}

///|
fn message_body_bytes(payload : MessagePayload) -> Bytes {
  @ffi.to_wstr(payload.message)
}

///|
fn optional_path_from_wstr(bytes : Bytes) -> String? {
  let value = @ffi.from_wstr_lossy(bytes)
  if value.is_empty() {
    None
  } else {
    Some(value)
  }
}

///|
fn level_to_int(level : String?) -> Int {
  match level {
    Some("warning") => 1
    Some("error") => 2
    _ => 0
  }
}

///|
fn message_level(payload : MessagePayload) -> Int {
  level_to_int(payload.level)
}

///|
fn show_message(window : Int64, payload : MessagePayload) -> MessageReply {
  ignore(
    message_dialog_ffi(
      window,
      message_title_bytes(payload),
      message_body_bytes(payload),
      message_level(payload),
    ),
  )
  MessageReply::{ acknowledged: true }
}

///|
fn confirm_message(window : Int64, payload : MessagePayload) -> ConfirmReply {
  let confirmed = confirm_dialog_ffi(
    window,
    message_title_bytes(payload),
    message_body_bytes(payload),
    message_level(payload),
  )
  ConfirmReply::{ confirmed, }
}

///|
fn file_dialog_path(
  window : Int64,
  payload : FileDialogPayload,
  callback : (Int64, Bytes, Bytes) -> Bytes,
) -> String? {
  optional_path_from_wstr(
    callback(window, to_wstr(payload.title), to_wstr(payload.path)),
  )
}

///|
fn emit_activity(
  extension : @runtime.ExtensionContext,
  operation : String,
  path? : String? = None,
  level? : String? = None,
) -> Unit {
  extension.emit("activity", DialogActivity::{ operation, path, level })
}

///|
/// Builds the native `dialog` extension for new application code.
///
/// Exposes `message`, `confirm`, `openFile`, and `saveFile` through
/// `window.__MoonBit__.dialog`.
pub fn extension() -> @runtime.Extension {
  @runtime.Extension::new("dialog", fn(extension) {
    let window = extension.webview().get_window()

    extension.op_result("message", fn(payload : MessagePayload) {
      with_supported(fn() {
        let reply = show_message(window, payload)
        emit_activity(extension, "message", level=payload.level)
        Ok(reply)
      })
    })

    extension.op_result("confirm", fn(payload : MessagePayload) {
      with_supported(fn() {
        let reply = confirm_message(window, payload)
        emit_activity(extension, "confirm", level=payload.level)
        Ok(reply)
      })
    })

    extension.op_result("openFile", fn(payload : FileDialogPayload) {
      with_supported(fn() {
        let path = file_dialog_path(window, payload, open_file_dialog_ffi)
        emit_activity(extension, "openFile", path~)
        Ok(FileDialogReply::{ path, })
      })
    })

    extension.op_result("saveFile", fn(payload : FileDialogPayload) {
      with_supported(fn() {
        let path = file_dialog_path(window, payload, save_file_dialog_ffi)
        emit_activity(extension, "saveFile", path~)
        Ok(FileDialogReply::{ path, })
      })
    })
  })
}

///|
pub fn app_extension() -> @app.AppExtension {
  @app.AppExtension::new("dialog", fn(_context) { Ok(extension()) })
}

///|
test "dialog level maps to native code" {
  assert_eq(level_to_int(None), 0)
  assert_eq(level_to_int(Some("warning")), 1)
  assert_eq(level_to_int(Some("error")), 2)
}

///|
test "dialog empty wide string becomes None path" {
  assert_eq(optional_path_from_wstr(@ffi.to_wstr("")), None)
  assert_eq(optional_path_from_wstr(@ffi.to_wstr("demo.txt")), Some("demo.txt"))
}
