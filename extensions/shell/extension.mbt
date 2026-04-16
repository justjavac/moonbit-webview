///|
let extension_id = "justjavac/lepus-shell"

///|
let extension_namespace = "shell"

///|
struct ShellPayload {
  target : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct RevealItemPayload {
  path : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ShellReply {
  launched : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ShellActivity {
  operation : String
  target : String
} derive(ToJson, FromJson, Debug, Eq)

///|
extern "C" fn is_windows_ffi() -> Bool = "extensions_shell_is_windows"

///|
#borrow(target)
extern "C" fn open_shell_ffi(target : Bytes) -> Bool = "extensions_shell_open"

///|
#borrow(path)
extern "C" fn reveal_item_ffi(path : Bytes) -> Bool = "extensions_shell_reveal_item"

///|
/// Verifies that the shell extension is available on the current platform.
fn ensure_supported() -> Result[Unit, String] {
  if is_windows_ffi() {
    Ok(())
  } else {
    Err("shell extension currently supports Windows native builds only")
  }
}

///|
/// Runs a shell operation only when native support is available.
fn[Reply] with_supported(
  callback : () -> Result[Reply, String],
) -> Result[Reply, String] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) => callback()
  }
}

///|
/// Rejects empty shell targets before calling native launchers.
fn validate_target(value : String, label : String) -> Result[String, String] {
  if value.is_empty() {
    Err(label + " must not be empty")
  } else {
    Ok(value)
  }
}

///|
/// Emits a shell activity event for JavaScript listeners.
fn emit_activity(
  extension : @core.ExtensionContext,
  operation : String,
  target : String,
) -> Unit {
  extension.emit("activity", ShellActivity::{ operation, target })
}

///|
/// Runs one native shell action and converts its result into the common reply type.
fn perform_shell_action(
  extension : @core.ExtensionContext,
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
/// Builds the `shell` extension for direct installation.
/// Install it manually when trusted local content needs shell launching helpers
/// on one webview.
pub fn extension() -> @core.Extension {
  @core.Extension::new(extension_id, extension_namespace, fn(extension) {
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
/// Builds the declarative `shell` extension spec.
/// Use this when shell integration should be linked through registry-based app
/// composition.
pub fn spec() -> @core.ExtensionSpec {
  @core.ExtensionSpec::new(extension_id, extension_namespace, fn(_context) {
    Ok(extension())
  })
}
