///|
struct GlobalHotkeyPayload {
  accelerator : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct EmptyPayload {} derive(ToJson, FromJson, Show, Eq)

///|
struct GlobalHotkeyReply {
  registered : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct GlobalHotkeyListReply {
  accelerators : Array[String]
} derive(ToJson, FromJson, Show, Eq)

///|
struct GlobalHotkeyActivity {
  operation : String
  accelerator : String
} derive(ToJson, FromJson, Show, Eq)

///|
fn ensure_supported() -> Result[Unit, String] {
  @sys_global_hotkey.ensure_supported()
}

fn init_manager() -> @sys_global_hotkey.GlobalHotkeyManager? {
  match ensure_supported() {
    Ok(_) =>
      match @sys_global_hotkey.create() {
        Ok(handle) => Some(handle)
        Err(_) => None
      }
    Err(_) => None
  }
}

fn[Reply] with_manager(
  manager : @sys_global_hotkey.GlobalHotkeyManager?,
  callback : (@sys_global_hotkey.GlobalHotkeyManager) -> Result[Reply, String],
) -> Result[Reply, String] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) =>
      match manager {
        Some(handle) => callback(handle)
        None => Err("globalHotkey extension failed to initialize")
      }
  }
}

fn list_or_empty(
  manager : @sys_global_hotkey.GlobalHotkeyManager?,
  selector : (@sys_global_hotkey.GlobalHotkeyManager) -> Array[String],
) -> GlobalHotkeyListReply {
  match manager {
    Some(handle) => GlobalHotkeyListReply::{ accelerators: selector(handle) }
    None => GlobalHotkeyListReply::{ accelerators: [] }
  }
}

fn destroy_manager(manager : @sys_global_hotkey.GlobalHotkeyManager?) -> Unit {
  match manager {
    Some(handle) => handle.destroy()
    None => ()
  }
}

fn emit_activity(
  extension : @runtime.ExtensionContext,
  operation : String,
  accelerator : String,
) -> Unit {
  extension.emit("activity", GlobalHotkeyActivity::{ operation, accelerator })
}

///|
fn trigger_poller_script() -> String {
  (
    #|(() => {
    #|  const moonbit = window.__MoonBit__;
    #|  if (!moonbit || !moonbit.events || typeof moonbit.events["@@emitExtensionEvent"] !== "function") {
    #|    return;
    #|  }
    #|  const state = moonbit["@@state"] && typeof moonbit["@@state"] === "object"
    #|    ? moonbit["@@state"]
    #|    : (moonbit["@@state"] = Object.create(null));
    #|  if (state.globalHotkeyPoller) {
    #|    return;
    #|  }
    #|  state.globalHotkeyPoller = window.setInterval(() => {
    #|    if (typeof moonbit.extension !== "function") {
    #|      return;
    #|    }
    #|    const extension = moonbit.extension("globalHotkey");
    #|    if (!extension || typeof extension.drainTriggered !== "function") {
    #|      return;
    #|    }
    #|    extension.drainTriggered({})
    #|      .then((reply) => {
    #|        if (!reply || !Array.isArray(reply.accelerators)) {
    #|          return;
    #|        }
    #|        for (const accelerator of reply.accelerators) {
    #|          moonbit.events["@@emitExtensionEvent"]("globalHotkey", "triggered", {
    #|            accelerator,
    #|          });
    #|        }
    #|      })
    #|      .catch(() => {});
    #|  }, 150);
    #|})();
  )
}

///|
fn install_trigger_poller(extension : @runtime.ExtensionContext) -> Unit {
  let script = trigger_poller_script()
  let webview = extension.webview()
  webview.init(script)
  webview.dispatch(fn() { webview.eval(script) })
}

///|
/// Builds the `globalHotkey` extension for new application code.
pub fn extension() -> @runtime.Extension {
  let mut manager : @sys_global_hotkey.GlobalHotkeyManager? = None
  @runtime.Extension::new(
    "globalHotkey",
    fn(extension) {
      manager = init_manager()

      extension.op_result("register", fn(payload : GlobalHotkeyPayload) {
        with_manager(manager, fn(handle) {
          match handle.register(payload.accelerator) {
            Err(error) => Err(error)
            Ok(registered) => {
              emit_activity(extension, "register", payload.accelerator)
              Ok(GlobalHotkeyReply::{ registered, })
            }
          }
        })
      })

      extension.op_result("unregister", fn(payload : GlobalHotkeyPayload) {
        with_manager(manager, fn(handle) {
          match handle.unregister(payload.accelerator) {
            Err(error) => Err(error)
            Ok(registered) => {
              emit_activity(extension, "unregister", payload.accelerator)
              Ok(GlobalHotkeyReply::{ registered, })
            }
          }
        })
      })

      extension.op_result("list", fn(_payload : EmptyPayload) {
        Ok(list_or_empty(manager, fn(handle) { handle.list() }))
      })

      extension.op_result("drainTriggered", fn(_payload : EmptyPayload) {
        Ok(list_or_empty(manager, fn(handle) { handle.drain_triggered() }))
      })
    },
    on_install=fn(extension) { install_trigger_poller(extension) },
    on_destroy=fn(_extension) {
      destroy_manager(manager)
      manager = None
    },
  )
}

///|
pub fn app_extension() -> @app.AppExtension {
  @app.AppExtension::new("globalHotkey", fn(_context) { Ok(extension()) })
}
