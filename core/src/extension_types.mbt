///|
/// Preferred top-level runtime abstraction for extending a `@webview.Webview`.
struct Extension {
  id : String
  js_namespace : String
  register : (ExtensionContext) -> Unit
  on_install : (ExtensionContext) -> Unit
  on_destroy : (ExtensionContext) -> Unit
  scripts : Array[String]
}

///|
/// Registration context handed to an extension during installation.
struct ExtensionContext {
  host : ExtensionHost
  extension_id : String
  extension_namespace : String
}

///|
/// Primary host wrapper for registering ops-backed extensions.
struct ExtensionHost {
  webview : @webview.Webview
  extension_ids : Map[String, String]
  extension_namespaces : Map[String, String]
  apis : Map[String, Bool]
  destroy_hooks : Map[String, () -> Unit]
  destroy_hook_name : String
  default_runtime_cache : OpRuntime?
}

///|
/// Builds an extension value that can later be installed on a `@webview.Webview`
/// or `ExtensionHost`.
pub fn Extension::new(
  id : String,
  js_namespace : String,
  register : (ExtensionContext) -> Unit,
  on_install? : (ExtensionContext) -> Unit = fn(_context) {  },
  on_destroy? : (ExtensionContext) -> Unit = fn(_context) {  },
  scripts? : Array[String] = [],
) -> Extension {
  Extension::{ id, js_namespace, register, on_install, on_destroy, scripts }
}

///|
/// Returns the stable extension id.
/// This id is used for manifest selection, generated registries, and duplicate
/// detection during installation.
pub fn Extension::id(self : Extension) -> String {
  self.id
}

///|
/// Returns the JavaScript namespace exposed by this extension.
/// Runtime op names and `window.__MoonBit__.<namespace>` both use this value.
pub fn Extension::js_namespace(self : Extension) -> String {
  self.js_namespace
}

///|
/// Returns the stable extension id currently being installed.
/// Extension callbacks can use this when they need to surface manifest- or
/// tooling-facing identities.
pub fn ExtensionContext::id(self : ExtensionContext) -> String {
  self.extension_id
}

///|
/// Returns the JavaScript namespace currently being installed.
/// Extension callbacks should use this when emitting events or deriving runtime
/// op names.
pub fn ExtensionContext::js_namespace(self : ExtensionContext) -> String {
  self.extension_namespace
}

///|
/// Returns the underlying webview that owns this extension host.
/// Drop down to this accessor when an extension needs raw webview APIs or native
/// handles.
pub fn ExtensionContext::webview(self : ExtensionContext) -> @webview.Webview {
  self.host.webview
}

///|
/// Emits an extension-scoped event to JavaScript.
/// Listeners receive the event under this extension's namespace on the shared
/// `window.__MoonBit__.events` channel.
pub fn[Payload : ToJson] ExtensionContext::emit(
  self : ExtensionContext,
  event_name : String,
  payload : Payload,
) -> Unit {
  self.host.emit(self.extension_namespace, event_name, payload)
}

///|
/// Registers a typed extension op exposed through `window.__MoonBit__`.
/// The callback input is decoded from JSON and the reply is re-encoded before
/// being returned to JavaScript callers.
pub fn[Payload : @json.FromJson, Reply : ToJson] ExtensionContext::op(
  self : ExtensionContext,
  api_name : String,
  callback : (Payload) -> Reply,
) -> Unit {
  let op_name = self.register_api(api_name)
  op_runtime(self.host.webview).handle(op_name, callback)
}

///|
/// Registers a typed extension op that can return explicit errors.
/// Returning `Err(message)` surfaces a structured failure back to JavaScript
/// instead of forcing the callback to abort.
pub fn[Payload : @json.FromJson, Reply : ToJson] ExtensionContext::op_result(
  self : ExtensionContext,
  api_name : String,
  callback : (Payload) -> Result[Reply, String],
) -> Unit {
  let op_name = self.register_api(api_name)
  op_runtime(self.host.webview).handle_result(op_name, callback)
}

///|
/// Returns the installed JavaScript helper scripts owned by this extension.
fn Extension::scripts(self : Extension) -> Array[String] {
  self.scripts
}
