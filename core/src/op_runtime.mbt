///|
let default_op_runtimes : Map[Int64, OpRuntime] = {}

///|
priv struct OpInvocation {
  name : String
  payload : Json
} derive(FromJson)

///|
priv struct OpRuntime {
  webview : @webview.Webview
  registry : OpRegistry
  binding_name : String
  destroy_hook_name : String
  default_registry_key : Int64?
  mut extension_host : ExtensionHost?
}

///|
/// Returns the default op runtime attached to a webview, creating it lazily.
fn op_runtime(webview : @webview.Webview) -> OpRuntime {
  let key = webview.runtime_handle_id()
  match default_op_runtimes.get(key) {
    Some(runtime) => runtime
    None => {
      let runtime = make_op_runtime(webview, default_registry_key=Some(key))
      default_op_runtimes.set(key, runtime)
      runtime
    }
  }
}

///|
/// Ensures the core JavaScript bridge and native op binding are installed.
/// Calling this repeatedly is safe because the default runtime is cached per
/// webview identity.
pub fn ensure_core_runtime(webview : @webview.Webview) -> Unit {
  ignore(op_runtime(webview))
}

///|
/// Creates an op runtime, binds the dispatch bridge, and installs cleanup hooks.
fn make_op_runtime(
  webview : @webview.Webview,
  binding_name? : String = moonbit_op_binding_name_value,
  default_registry_key? : Int64? = None,
) -> OpRuntime {
  guard !webview.has_binding(binding_name) else {
    abort("OpRuntime::new: binding name already in use: " + binding_name)
  }
  let destroy_hook_name = "op-runtime:" + binding_name
  let runtime = OpRuntime::{
    webview,
    registry: OpRegistry::new(),
    binding_name,
    destroy_hook_name,
    default_registry_key,
    extension_host: None,
  }
  install_moonbit_core_runtime(webview)
  webview.bind(binding_name, fn(id, req) { runtime.handle_request(id, req) })
  webview.register_destroy_hook(destroy_hook_name, fn() { runtime.destroy() })
  runtime
}

///|
/// Unregisters runtime bindings and clears any cached default runtime state.
fn OpRuntime::destroy(self : OpRuntime) -> Unit {
  match self.default_registry_key {
    Some(key) => default_op_runtimes.remove(key)
    None => ()
  }
  self.extension_host = None
  self.webview.unregister_destroy_hook(self.destroy_hook_name)
  self.webview.unbind(self.binding_name)
}

///|
/// Returns the cached extension host associated with this runtime, if present.
fn OpRuntime::extension_host_cache(self : OpRuntime) -> ExtensionHost? {
  self.extension_host
}

///|
/// Stores the default extension host associated with this runtime.
fn OpRuntime::cache_extension_host(
  self : OpRuntime,
  host : ExtensionHost,
) -> Unit {
  self.extension_host = Some(host)
}

///|
/// Clears the cached default extension host reference.
fn OpRuntime::clear_extension_host_cache(self : OpRuntime) -> Unit {
  self.extension_host = None
}

///|
/// Registers an op handler and exposes it to JavaScript.
fn[Payload : @json.FromJson, Reply : ToJson] OpRuntime::handle(
  self : OpRuntime,
  name : String,
  callback : (Payload) -> Reply,
) -> Unit {
  self.registry.handle(name, callback)
  register_moonbit_op(self.webview, name)
}

///|
/// Registers an op handler with explicit string error support and exposes it to JavaScript.
fn[Payload : @json.FromJson, Reply : ToJson] OpRuntime::handle_result(
  self : OpRuntime,
  name : String,
  callback : (Payload) -> Result[Reply, String],
) -> Unit {
  self.registry.handle_result(name, callback)
  register_moonbit_op(self.webview, name)
}

///|
/// Handles one raw binding request from JavaScript and returns the serialized reply.
fn OpRuntime::handle_request(
  self : OpRuntime,
  raw_id : Bytes,
  raw_req : Bytes,
) -> Unit {
  let id = @ffi.from_cstr(raw_id)
  let reply = parse_op_request(@ffi.from_cstr(raw_req)).bind(fn(request) {
    self.registry.call(request.name, request.payload)
  })
  match reply {
    Ok(reply) => self.webview.response(id, 0, reply.stringify())
    Err(message) =>
      self.webview.response(id, 1, Json::string(message).stringify())
  }
}

///|
/// Decodes the single op invocation payload expected by the JavaScript bridge.
fn parse_op_request(raw_req : String) -> Result[OpInvocation, String] {
  let request_json : Result[Json, _] = try? @json.parse(raw_req)
  request_json
  .map_err(fn(err) { err.to_string() })
  .bind(fn(request_json) {
    let request_args : Result[Array[OpInvocation], _] = try? @json.from_json(
      request_json,
    )
    request_args
    .map_err(fn(err) { err.to_string() })
    .bind(expect_single_op_invocation)
  })
}

///|
/// Ensures the JavaScript bridge supplied exactly one op invocation argument.
fn expect_single_op_invocation(
  request_args : Array[OpInvocation],
) -> Result[OpInvocation, String] {
  if request_args.length() == 1 {
    Ok(request_args[0])
  } else {
    Err("Expected exactly one op invocation argument")
  }
}
