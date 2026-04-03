///|
/// Preferred top-level runtime abstraction for extending a `@webview.Webview` or `App`.
struct Extension {
  name : String
  register : (ExtensionContext) -> Unit
  on_install : (ExtensionContext) -> Unit
  on_destroy : (ExtensionContext) -> Unit
  helper_script : (String) -> String?
}

///|
/// Registration context handed to an extension during installation.
struct ExtensionContext {
  host : ExtensionHost
  extension_name : String
}

///|
/// Primary host wrapper for registering ops-backed extensions.
struct ExtensionHost {
  webview : @webview.Webview
  extensions : Map[String, Bool]
  apis : Map[String, Bool]
  destroy_hooks : Map[String, () -> Unit]
  destroy_hook_name : String
  default_runtime_cache : OpRuntime?
}

///|
/// Builds an extension value that can later be installed on a `@webview.Webview`,
/// `App`, or `ExtensionHost`.
pub fn Extension::new(
  name : String,
  register : (ExtensionContext) -> Unit,
  on_install? : (ExtensionContext) -> Unit = fn(_context) {  },
  on_destroy? : (ExtensionContext) -> Unit = fn(_context) {  },
  helper_script? : (String) -> String? = fn(_root_name) { None },
) -> Extension {
  Extension::{ name, register, on_install, on_destroy, helper_script }
}

///|
/// Returns the extension name.
pub fn Extension::name(self : Extension) -> String {
  self.name
}

///|
fn Extension::helper_script(self : Extension, root_name : String) -> String? {
  (self.helper_script)(root_name)
}

///|
/// Returns the extension name currently being installed.
pub fn ExtensionContext::name(self : ExtensionContext) -> String {
  self.extension_name
}

///|
/// Returns the underlying webview that owns this extension host.
pub fn ExtensionContext::webview(self : ExtensionContext) -> @webview.Webview {
  self.host.webview
}

///|
/// Emits an extension-scoped event to JavaScript.
pub fn[Payload : ToJson] ExtensionContext::emit(
  self : ExtensionContext,
  event_name : String,
  payload : Payload,
) -> Unit {
  self.host.emit(self.extension_name, event_name, payload)
}

///|
/// Registers a typed extension op exposed through `window.__MoonBit__`.
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
pub fn[Payload : @json.FromJson, Reply : ToJson] ExtensionContext::op_result(
  self : ExtensionContext,
  api_name : String,
  callback : (Payload) -> Result[Reply, String],
) -> Unit {
  let op_name = self.register_api(api_name)
  op_runtime(self.host.webview).handle_result(op_name, callback)
}

///|
/// Creates an extension host for a webview.
pub fn ExtensionHost::new(webview : @webview.Webview) -> ExtensionHost {
  make_extension_host(webview)
}

///|
/// Returns the default extension host attached to this webview.
pub fn extension_host(webview : @webview.Webview) -> ExtensionHost {
  let runtime = op_runtime(webview)
  match runtime.extension_host_cache() {
    Some(host) => host
    None => {
      let host = make_extension_host(
        webview,
        default_runtime_cache=Some(runtime),
      )
      runtime.cache_extension_host(host)
      host
    }
  }
}

///|
/// Returns the default extension host attached to this app runtime.
pub fn App::extension_host(self : App) -> ExtensionHost {
  extension_host(self.webview())
}

///|
/// Installs an extension into the webview's default extension host.
pub fn install_extension(
  webview : @webview.Webview,
  extension : Extension,
) -> Unit {
  extension_host(webview).install(extension)
}

///|
/// Installs an extension into the app runtime.
pub fn App::install_extension(self : App, extension : Extension) -> Unit {
  install_app_extension_on_app(self, extension)
}

///|
/// Emits an extension-scoped event from the webview's default extension host.
pub fn[Payload : ToJson] emit_extension(
  webview : @webview.Webview,
  extension_name : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  extension_host(webview).emit(extension_name, event_name, payload)
}

///|
/// Emits an extension-scoped event from the app runtime.
pub fn[Payload : ToJson] App::emit_extension(
  self : App,
  extension_name : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  emit_app_extension(self, extension_name, event_name, payload)
}

///|
/// Installs an extension into the host.
pub fn ExtensionHost::install(
  self : ExtensionHost,
  extension : Extension,
) -> Unit {
  guard !extension_is_reserved_name(extension.name) else {
    abort("ExtensionHost::install: reserved extension name: " + extension.name)
  }
  guard self.extensions.get(extension.name) is None else {
    abort(
      "ExtensionHost::install: extension already installed: " + extension.name,
    )
  }
  let context = ExtensionContext::{ host: self, extension_name: extension.name }
  self.extensions.set(extension.name, true)
  self.destroy_hooks.set(extension.name, fn() {
    (extension.on_destroy)(context)
  })
  install_extension_namespace(self.webview, extension.name)
  install_extension_js_helper(
    self.webview,
    extension.helper_script(moonbit_global_name),
  )
  (extension.register)(context)
  (extension.on_install)(context)
}

///|
/// Emits an extension-scoped event from the host to JavaScript.
pub fn[Payload : ToJson] ExtensionHost::emit(
  self : ExtensionHost,
  extension_name : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  guard self.extensions.get(extension_name) is Some(_) else {
    abort("ExtensionHost::emit: extension is not installed: " + extension_name)
  }
  let payload_json = ToJson::to_json(payload).stringify()
  let script = make_extension_emit_script(
    extension_name, event_name, payload_json,
  )
  self.webview.dispatch(fn() { self.webview.eval(script) })
}

///|
/// Drops all registered extension metadata.
pub fn ExtensionHost::destroy(self : ExtensionHost) -> Unit {
  match self.default_runtime_cache {
    Some(runtime) => runtime.clear_extension_host_cache()
    None => ()
  }
  self.webview.unregister_destroy_hook(self.destroy_hook_name)
  for _, hook in self.destroy_hooks {
    hook()
  }
  self.extensions.clear()
  self.apis.clear()
  self.destroy_hooks.clear()
}

///|
/// Runs the underlying webview loop.
pub fn ExtensionHost::run(self : ExtensionHost) -> Unit {
  self.webview.run()
}

///|
fn ExtensionContext::register_api(
  self : ExtensionContext,
  api_name : String,
) -> String {
  guard !extension_is_reserved_api_name(api_name) else {
    abort(
      "ExtensionContext::register_api: reserved API name: " +
      self.extension_name +
      "." +
      api_name,
    )
  }
  let registry_key = extension_api_registry_key(self.extension_name, api_name)
  guard self.host.apis.get(registry_key) is None else {
    abort(
      "ExtensionContext::register_api: API already registered: " +
      self.extension_name +
      "." +
      api_name,
    )
  }
  self.host.apis.set(registry_key, true)
  extension_op_name(self.extension_name, api_name)
}

///|
fn make_extension_host(
  webview : @webview.Webview,
  default_runtime_cache? : OpRuntime? = None,
) -> ExtensionHost {
  let destroy_hook_name = extension_host_destroy_hook_name()
  let host = ExtensionHost::{
    webview,
    extensions: {},
    apis: {},
    destroy_hooks: {},
    destroy_hook_name,
    default_runtime_cache,
  }
  let _ = op_runtime(webview)
  webview.register_destroy_hook(destroy_hook_name, fn() { host.destroy() })
  host
}

///|
fn extension_api_registry_key(
  extension_name : String,
  api_name : String,
) -> String {
  extension_name + "\u0000" + api_name
}

///|
fn extension_op_name(extension_name : String, api_name : String) -> String {
  "op_" + extension_name + "_" + api_name
}

///|
fn extension_host_destroy_hook_name() -> String {
  "extension-host"
}

///|
fn extension_is_disallowed_js_property_name(name : String) -> Bool {
  name.has_prefix("@@") ||
  name == "__proto__" ||
  name == "prototype" ||
  name == "constructor"
}

///|
fn extension_is_reserved_name(extension_name : String) -> Bool {
  extension_is_disallowed_js_property_name(extension_name)
}

///|
fn extension_is_reserved_api_name(api_name : String) -> Bool {
  extension_is_disallowed_js_property_name(api_name)
}
