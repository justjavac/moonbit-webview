///|
let extension_id = "justjavac/lepus-global-hotkey"

///|
let extension_namespace = "globalHotkey"

///|
struct GlobalHotkeyPayload {
  accelerator : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct EmptyPayload {} derive(ToJson, FromJson, Debug, Eq)

///|
struct GlobalHotkeyReply {
  registered : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct GlobalHotkeyListReply {
  accelerators : Array[String]
} derive(ToJson, FromJson, Debug, Eq)

///|
struct GlobalHotkeyActivity {
  operation : String
  accelerator : String
} derive(ToJson, FromJson, Debug, Eq)

///|
/// Verifies that global hotkeys are available on the current platform.
fn ensure_supported() -> Result[Unit, String] {
  @sys_global_hotkey.ensure_supported()
}

///|
/// Creates the native hotkey manager when support is available.
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

///|
/// Runs a hotkey operation with the initialized manager when available.
fn[Reply] with_manager(
  manager : @sys_global_hotkey.GlobalHotkeyManager?,
  callback : (@sys_global_hotkey.GlobalHotkeyManager) -> Result[Reply, String],
) -> Result[Reply, String] {
  ensure_supported().bind(fn(_) {
    match manager {
      Some(handle) => callback(handle)
      None => Err("globalHotkey extension failed to initialize")
    }
  })
}

///|
/// Returns the selected accelerator list or an empty result when the manager is unavailable.
fn list_or_empty(
  manager : @sys_global_hotkey.GlobalHotkeyManager?,
  selector : (@sys_global_hotkey.GlobalHotkeyManager) -> Array[String],
) -> GlobalHotkeyListReply {
  match manager {
    Some(handle) => GlobalHotkeyListReply::{ accelerators: selector(handle) }
    None => GlobalHotkeyListReply::{ accelerators: [] }
  }
}

///|
/// Destroys the native manager when it was initialized successfully.
fn destroy_manager(manager : @sys_global_hotkey.GlobalHotkeyManager?) -> Unit {
  match manager {
    Some(handle) => handle.destroy()
    None => ()
  }
}

///|
/// Emits a global-hotkey activity event for JavaScript listeners.
fn emit_activity(
  extension : @core.ExtensionContext,
  operation : String,
  accelerator : String,
) -> Unit {
  extension.emit("activity", GlobalHotkeyActivity::{ operation, accelerator })
}

///|
/// Returns the JavaScript poller script that forwards triggered hotkeys as extension events.
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
    #|    const extension = moonbit.globalHotkey;
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

///|
/// Builds the `globalHotkey` extension for direct installation.
/// Install it manually when trusted local content needs runtime hotkey
/// registration without going through an app registry.
pub fn extension() -> @core.Extension {
  let mut manager : @sys_global_hotkey.GlobalHotkeyManager? = None
  @core.Extension::new(
    extension_id,
    extension_namespace,
    fn(extension) {
      manager = init_manager()

      extension.op_result("register", fn(payload : GlobalHotkeyPayload) {
        with_manager(manager, fn(handle) {
          handle
          .register(payload.accelerator)
          .map(fn(registered) {
            emit_activity(extension, "register", payload.accelerator)
            GlobalHotkeyReply::{ registered, }
          })
        })
      })

      extension.op_result("unregister", fn(payload : GlobalHotkeyPayload) {
        with_manager(manager, fn(handle) {
          handle
          .unregister(payload.accelerator)
          .map(fn(registered) {
            emit_activity(extension, "unregister", payload.accelerator)
            GlobalHotkeyReply::{ registered, }
          })
        })
      })

      extension.op_result("list", fn(_payload : EmptyPayload) {
        Ok(list_or_empty(manager, fn(handle) { handle.list() }))
      })

      extension.op_result("drainTriggered", fn(_payload : EmptyPayload) {
        Ok(list_or_empty(manager, fn(handle) { handle.drain_triggered() }))
      })
    },
    on_destroy=fn(_extension) {
      destroy_manager(manager)
      manager = None
    },
    scripts=[trigger_poller_script()],
  )
}

///|
/// Builds the declarative `globalHotkey` extension spec.
/// Use this when global hotkeys should be linked through registry-based app
/// composition.
pub fn spec() -> @core.ExtensionSpec {
  @core.ExtensionSpec::new(extension_id, extension_namespace, fn(_context) {
    Ok(extension())
  })
}
