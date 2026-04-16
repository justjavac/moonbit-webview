///|
let extension_id = "justjavac/lepus-tray"

///|
let extension_namespace = "tray"

///|
struct TrayShowPayload {
  tooltip : String?
} derive(ToJson, FromJson, Debug, Eq)

///|
struct TrayTooltipPayload {
  tooltip : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct EmptyPayload {} derive(ToJson, FromJson, Debug, Eq)

///|
struct TrayReply {
  visible : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct TrayActivity {
  operation : String
  tooltip : String?
} derive(ToJson, FromJson, Debug, Eq)

///|
/// Verifies that tray support is available on the current platform.
fn ensure_supported() -> Result[Unit, String] {
  @sys_tray.ensure_supported()
}

///|
/// Creates the native tray handle for the current app window when supported.
fn init_tray(extension : @core.ExtensionContext) -> @sys_tray.Tray? {
  match ensure_supported() {
    Ok(_) =>
      match @sys_tray.create(extension.webview().get_window()) {
        Ok(handle) => Some(handle)
        Err(_) => None
      }
    Err(_) => None
  }
}

///|
/// Runs a tray operation with the initialized tray handle when available.
fn[Reply] with_tray_handle(
  tray_handle : @sys_tray.Tray?,
  callback : (@sys_tray.Tray) -> Result[Reply, String],
) -> Result[Reply, String] {
  ensure_supported().bind(fn(_) {
    match tray_handle {
      Some(handle) => callback(handle)
      None => Err("tray extension failed to initialize")
    }
  })
}

///|
/// Destroys the native tray handle when one was created.
fn destroy_tray(tray_handle : @sys_tray.Tray?) -> Unit {
  match tray_handle {
    Some(handle) => handle.destroy()
    None => ()
  }
}

///|
/// Emits a tray activity event for JavaScript listeners.
fn emit_activity(
  extension : @core.ExtensionContext,
  operation : String,
  tooltip : String?,
) -> Unit {
  extension.emit("activity", TrayActivity::{ operation, tooltip })
}

///|
/// Builds the `tray` extension for direct installation.
/// Install it manually when a trusted desktop app wants tray control without
/// going through registry-based composition.
pub fn extension() -> @core.Extension {
  let mut tray_handle : @sys_tray.Tray? = None
  @core.Extension::new(
    extension_id,
    extension_namespace,
    fn(extension) {
      tray_handle = init_tray(extension)

      extension.op_result("show", fn(payload : TrayShowPayload) {
        with_tray_handle(tray_handle, fn(handle) {
          handle
          .show(tooltip=payload.tooltip)
          .map(fn(visible) {
            emit_activity(extension, "show", payload.tooltip)
            TrayReply::{ visible, }
          })
        })
      })

      extension.op_result("hide", fn(_payload : EmptyPayload) {
        with_tray_handle(tray_handle, fn(handle) {
          handle
          .hide()
          .map(fn(visible) {
            emit_activity(extension, "hide", None)
            TrayReply::{ visible, }
          })
        })
      })

      extension.op_result("setTooltip", fn(payload : TrayTooltipPayload) {
        with_tray_handle(tray_handle, fn(handle) {
          handle
          .set_tooltip(payload.tooltip)
          .map(fn(visible) {
            emit_activity(extension, "setTooltip", Some(payload.tooltip))
            TrayReply::{ visible, }
          })
        })
      })
    },
    on_destroy=fn(_extension) {
      destroy_tray(tray_handle)
      tray_handle = None
    },
  )
}

///|
/// Builds the declarative `tray` extension spec.
/// Register this when tray support should be selected through app planning or
/// tooling workflows.
pub fn spec() -> @core.ExtensionSpec {
  @core.ExtensionSpec::new(extension_id, extension_namespace, fn(_context) {
    Ok(extension())
  })
}
