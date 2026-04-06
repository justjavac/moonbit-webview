///|
/// Creates an extension host for a webview.
/// Most callers should prefer `extension_host(webview)` so the default cached
/// host is reused across helper layers.
pub fn ExtensionHost::new(webview : @webview.Webview) -> ExtensionHost {
  make_extension_host(webview)
}

///|
/// Returns the default extension host attached to this webview.
/// The host is created lazily and cached with the default op runtime so later
/// extension installs share one consistent bridge.
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
/// Installs an extension into the webview's default extension host.
/// This is the simplest way to expose one extension on a raw `@webview.Webview`
/// without manually managing host lifetime.
pub fn install_extension(
  webview : @webview.Webview,
  extension : Extension,
) -> Unit {
  extension_host(webview).install(extension)
}

///|
/// Emits an extension-scoped event from the webview's default extension host.
/// The event is serialized once and forwarded to JavaScript listeners under the
/// extension's namespace and event name.
pub fn[Payload : ToJson] emit_extension(
  webview : @webview.Webview,
  extension_namespace : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  extension_host(webview).emit(extension_namespace, event_name, payload)
}

///|
/// Installs an extension into the host.
/// Reserved namespaces plus duplicate ids or namespaces are rejected before
/// JavaScript helpers, ops, and lifecycle hooks are registered.
pub fn ExtensionHost::install(
  self : ExtensionHost,
  extension : Extension,
) -> Unit {
  guard extension.id.trim().to_string() != "" else {
    abort("ExtensionHost::install: extension id must not be empty")
  }
  guard extension.js_namespace.trim().to_string() != "" else {
    abort("ExtensionHost::install: extension namespace must not be empty")
  }
  guard !extension_namespace_is_reserved(extension.js_namespace) else {
    abort(
      "ExtensionHost::install: reserved extension namespace: " +
      extension.js_namespace,
    )
  }
  guard self.extension_ids.get(extension.id) is None else {
    abort(
      "ExtensionHost::install: extension already installed: " + extension.id,
    )
  }
  guard self.extension_namespaces.get(extension.js_namespace) is None else {
    abort(
      "ExtensionHost::install: extension namespace already installed: " +
      extension.js_namespace,
    )
  }
  let context = ExtensionContext::{
    host: self,
    extension_id: extension.id,
    extension_namespace: extension.js_namespace,
  }
  self.extension_ids.set(extension.id, extension.js_namespace)
  self.extension_namespaces.set(extension.js_namespace, extension.id)
  self.destroy_hooks.set(extension.id, fn() { (extension.on_destroy)(context) })
  install_extension_namespace(self.webview, extension.js_namespace)
  (extension.register)(context)
  install_extension_scripts(self.webview, extension.scripts())
  (extension.on_install)(context)
}

///|
/// Emits an extension-scoped event from the host to JavaScript.
/// The payload is converted to JSON and dispatched on the owning webview's main
/// thread so JavaScript observers receive it safely.
pub fn[Payload : ToJson] ExtensionHost::emit(
  self : ExtensionHost,
  extension_namespace : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  guard self.extension_namespaces.get(extension_namespace) is Some(_) else {
    abort(
      "ExtensionHost::emit: extension namespace is not installed: " +
      extension_namespace,
    )
  }
  let payload_json = ToJson::to_json(payload).stringify()
  let script = make_extension_emit_script(
    extension_namespace, event_name, payload_json,
  )
  self.webview.dispatch(fn() { self.webview.eval(script) })
}

///|
/// Drops all registered extension metadata.
/// Registered destroy hooks run before caches are cleared so extensions can
/// release native resources in a predictable order.
pub fn ExtensionHost::destroy(self : ExtensionHost) -> Unit {
  match self.default_runtime_cache {
    Some(runtime) => runtime.clear_extension_host_cache()
    None => ()
  }
  self.webview.unregister_destroy_hook(self.destroy_hook_name)
  for _, hook in self.destroy_hooks {
    hook()
  }
  self.extension_ids.clear()
  self.extension_namespaces.clear()
  self.apis.clear()
  self.destroy_hooks.clear()
}

///|
/// Runs the underlying webview loop.
/// This is a convenience passthrough for code that already holds an
/// `ExtensionHost` rather than the raw webview.
pub fn ExtensionHost::run(self : ExtensionHost) -> Unit {
  self.webview.run()
}

///|
/// Reserves an API name for one extension namespace and returns its fully
/// qualified op name.
fn ExtensionContext::register_api(
  self : ExtensionContext,
  api_name : String,
) -> String {
  guard !extension_is_reserved_api_name(api_name) else {
    abort(
      "ExtensionContext::register_api: reserved API name: " +
      self.extension_namespace +
      "." +
      api_name,
    )
  }
  let registry_key = extension_api_registry_key(
    self.extension_namespace,
    api_name,
  )
  guard self.host.apis.get(registry_key) is None else {
    abort(
      "ExtensionContext::register_api: API already registered: " +
      self.extension_namespace +
      "." +
      api_name,
    )
  }
  self.host.apis.set(registry_key, true)
  extension_op_name(self.extension_namespace, api_name)
}

///|
/// Creates a host wrapper and attaches its destroy hook to the owning webview.
fn make_extension_host(
  webview : @webview.Webview,
  default_runtime_cache? : OpRuntime? = None,
) -> ExtensionHost {
  let destroy_hook_name = extension_host_destroy_hook_name()
  let host = ExtensionHost::{
    webview,
    extension_ids: {},
    extension_namespaces: {},
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
/// Builds a unique registry key for one extension namespace and API pair.
fn extension_api_registry_key(
  extension_namespace : String,
  api_name : String,
) -> String {
  extension_namespace + "\u0000" + api_name
}

///|
/// Converts an extension namespace/API pair into the runtime op binding name.
fn extension_op_name(extension_namespace : String, api_name : String) -> String {
  "ext:" + extension_namespace + "/" + api_name
}

///|
/// Returns the destroy hook name used by the default extension host.
fn extension_host_destroy_hook_name() -> String {
  "extension-host"
}

///|
/// Rejects JavaScript property names that would be unsafe to expose on `window.__MoonBit__`.
fn extension_is_disallowed_js_property_name(name : String) -> Bool {
  name.has_prefix("@@") ||
  name == "__proto__" ||
  name == "prototype" ||
  name == "constructor"
}

///|
/// Returns whether an extension namespace is reserved.
fn extension_namespace_is_reserved(extension_namespace : String) -> Bool {
  extension_is_disallowed_js_property_name(extension_namespace)
}

///|
/// Returns whether an extension API name is reserved.
fn extension_is_reserved_api_name(api_name : String) -> Bool {
  extension_is_disallowed_js_property_name(api_name)
}
