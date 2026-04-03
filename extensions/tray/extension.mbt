///|
struct TrayShowPayload {
  tooltip : String?
} derive(ToJson, FromJson, Show, Eq)

///|
struct TrayTooltipPayload {
  tooltip : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct EmptyPayload {} derive(ToJson, FromJson, Show, Eq)

///|
struct TrayReply {
  visible : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct TrayActivity {
  operation : String
  tooltip : String?
} derive(ToJson, FromJson, Show, Eq)

///|
fn ensure_supported() -> Result[Unit, String] {
  @sys_tray.ensure_supported()
}

fn init_tray(extension : @runtime.ExtensionContext) -> @sys_tray.Tray? {
  match ensure_supported() {
    Ok(_) =>
      match @sys_tray.create(extension.webview().get_window()) {
        Ok(handle) => Some(handle)
        Err(_) => None
      }
    Err(_) => None
  }
}

fn[Reply] with_tray_handle(
  tray_handle : @sys_tray.Tray?,
  callback : (@sys_tray.Tray) -> Result[Reply, String],
) -> Result[Reply, String] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) =>
      match tray_handle {
        Some(handle) => callback(handle)
        None => Err("tray extension failed to initialize")
      }
  }
}

fn destroy_tray(tray_handle : @sys_tray.Tray?) -> Unit {
  match tray_handle {
    Some(handle) => handle.destroy()
    None => ()
  }
}

fn emit_activity(
  extension : @runtime.ExtensionContext,
  operation : String,
  tooltip : String?,
) -> Unit {
  extension.emit("activity", TrayActivity::{ operation, tooltip })
}

///|
/// Builds the `tray` extension for new application code.
pub fn extension() -> @runtime.Extension {
  let mut tray_handle : @sys_tray.Tray? = None
  @runtime.Extension::new(
    "tray",
    fn(extension) {
      tray_handle = init_tray(extension)

      extension.op_result("show", fn(payload : TrayShowPayload) {
        with_tray_handle(tray_handle, fn(handle) {
          match handle.show(tooltip=payload.tooltip) {
            Err(error) => Err(error)
            Ok(visible) => {
              emit_activity(extension, "show", payload.tooltip)
              Ok(TrayReply::{ visible, })
            }
          }
        })
      })

      extension.op_result("hide", fn(_payload : EmptyPayload) {
        with_tray_handle(tray_handle, fn(handle) {
          match handle.hide() {
            Err(error) => Err(error)
            Ok(visible) => {
              emit_activity(extension, "hide", None)
              Ok(TrayReply::{ visible, })
            }
          }
        })
      })

      extension.op_result("setTooltip", fn(payload : TrayTooltipPayload) {
        with_tray_handle(tray_handle, fn(handle) {
          match handle.set_tooltip(payload.tooltip) {
            Err(error) => Err(error)
            Ok(visible) => {
              emit_activity(extension, "setTooltip", Some(payload.tooltip))
              Ok(TrayReply::{ visible, })
            }
          }
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
pub fn app_extension() -> @app.AppExtension {
  @app.AppExtension::new("tray", fn(_context) { Ok(extension()) })
}
