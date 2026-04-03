///|
struct ShellPayload {
  target : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct RevealItemPayload {
  path : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct ShellReply {
  launched : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct ShellActivity {
  operation : String
  target : String
} derive(ToJson, FromJson, Show, Eq)

///|
extern "C" fn is_windows_ffi() -> Bool = "extensions_shell_is_windows"

///|
#borrow(target)
extern "C" fn open_shell_ffi(target : Bytes) -> Bool = "extensions_shell_open"

///|
#borrow(path)
extern "C" fn reveal_item_ffi(path : Bytes) -> Bool = "extensions_shell_reveal_item"

///|
fn ensure_supported() -> Result[Unit, String] {
  if is_windows_ffi() {
    Ok(())
  } else {
    Err("shell extension currently supports Windows native builds only")
  }
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
fn validate_target(value : String, label : String) -> Result[String, String] {
  if value.is_empty() {
    Err(label + " must not be empty")
  } else {
    Ok(value)
  }
}

///|
fn emit_activity(
  extension : @runtime.ExtensionContext,
  operation : String,
  target : String,
) -> Unit {
  extension.emit("activity", ShellActivity::{ operation, target })
}

///|
fn perform_shell_action(
  extension : @runtime.ExtensionContext,
  operation : String,
  target : String,
  label : String,
  launcher : (Bytes) -> Bool,
) -> Result[ShellReply, String] {
  match validate_target(target, label) {
    Err(error) => Err(error)
    Ok(target) => {
      guard launcher(@ffi.to_wstr(target)) else {
        return Err("shell.\{operation} failed")
      }
      emit_activity(extension, operation, target)
      Ok(ShellReply::{ launched: true })
    }
  }
}

///|
/// Builds the `shell` extension for new application code.
pub fn extension() -> @runtime.Extension {
  @runtime.Extension::new("shell", fn(extension) {
    extension.op_result("open", fn(payload : ShellPayload) {
      with_supported(fn() {
        perform_shell_action(
          extension,
          "open",
          payload.target,
          "shell.open target",
          open_shell_ffi,
        )
      })
    })

    extension.op_result("revealItem", fn(payload : RevealItemPayload) {
      with_supported(fn() {
        perform_shell_action(
          extension,
          "revealItem",
          payload.path,
          "shell.revealItem path",
          reveal_item_ffi,
        )
      })
    })
  })
}

///|
pub fn app_extension() -> @app.AppExtension {
  @app.AppExtension::new("shell", fn(_context) { Ok(extension()) })
}

///|
test "shell target validation rejects empty strings" {
  assert_eq(
    validate_target("", "shell.open target"),
    Err("shell.open target must not be empty"),
  )
  assert_eq(
    validate_target("https://example.com", "shell.open target"),
    Ok("https://example.com"),
  )
}
