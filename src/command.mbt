///|
/// A named command exchanged between JavaScript and MoonBit.
///
/// `name` is the logical command identifier and `payload` is arbitrary JSON.
/// This shape is used in both directions:
/// - JS -> MoonBit via `window.MoonBitBridge.send(name, payload)`
/// - MoonBit -> JS via `CommandBridge::send(name, payload)`
pub struct Command {
  name : String
  payload : Json
} derive(ToJson, FromJson, Show, Eq)

///|
/// Structured response returned from JS -> MoonBit commands.
///
/// `status` is `"ok"` for successful handlers and `"error"` for command
/// decode/dispatch failures or explicit handler errors.
///
/// When `status == "ok"`, `payload` contains the JSON-encoded reply and
/// `error` is `None`.
///
/// When `status == "error"`, `error` contains the failure message and
/// `payload` is `None`.
pub struct CommandResponse {
  status : String
  payload : Json?
  error : String?
} derive(ToJson, FromJson, Show, Eq)

///|
/// Builds a successful command response.
pub fn[Payload : ToJson] CommandResponse::ok(
  payload : Payload,
) -> CommandResponse {
  CommandResponse::{
    status: "ok",
    payload: Some(ToJson::to_json(payload)),
    error: None,
  }
}

///|
/// Builds a failed command response.
pub fn CommandResponse::error(message : String) -> CommandResponse {
  CommandResponse::{ status: "error", payload: None, error: Some(message) }
}

///|
/// Returns `true` when the response status is `"ok"`.
pub fn CommandResponse::is_ok(self : CommandResponse) -> Bool {
  self.status == "ok"
}

///|
/// High-level JSON command bridge built on top of `webview.bind()`.
///
/// It injects a JS helper object into the page and routes named commands to
/// registered MoonBit handlers.
///
/// The injected JS helper exposes:
/// - `window[global_name].send(name, payload)` for JS -> MoonBit request/reply
/// - `window[global_name].onCommand(listener)` for MoonBit -> JS events
///
/// JS -> MoonBit resolves to a `CommandResponse`, so command-level failures are
/// encoded in the response object instead of rejecting the promise.
struct CommandBridge {
  webview : Webview
  global_name : String
  event_name : String
  handlers : Map[String, (Json) -> CommandResponse]
}

///|
/// Creates and installs a command bridge for the given webview.
///
/// On the JavaScript side this exposes:
/// - `window[global_name].send(name, payload)` returning `Promise<CommandResponse>`
/// - `window[global_name].onCommand(listener)` for MoonBit -> JS events
///
/// Parameters:
/// - `global_name` controls the injected `window[...]` object name
/// - `binding_name` controls the internal JS -> MoonBit webview binding name
/// - `event_name` controls the browser event used for MoonBit -> JS delivery
pub fn CommandBridge::new(
  webview : Webview,
  global_name? : String = "MoonBitBridge",
  binding_name? : String = "__moonbit_command",
  event_name? : String = "moonbit:command",
) -> CommandBridge {
  let bridge = CommandBridge::{ webview, global_name, event_name, handlers: {} }
  bridge.webview.bind(binding_name, fn(id, req) {
    bridge.handle_request(id, req)
  })
  bridge.webview.init(
    make_command_bridge_script(global_name, binding_name, event_name),
  )
  bridge
}

///|
/// Returns the injected global object name on the JS side.
pub fn CommandBridge::global_name(self : CommandBridge) -> String {
  self.global_name
}

///|
/// Returns the browser event name used for native-to-JS commands.
pub fn CommandBridge::event_name(self : CommandBridge) -> String {
  self.event_name
}

///|
/// Registers a typed command handler.
///
/// Use `Json` as `Payload` if you want to handle raw JSON directly.
///
/// When JS calls `window.MoonBitBridge.send(name, payload)`, the bridge:
/// - looks up the handler registered under `name`
/// - decodes `payload` into `Payload`
/// - encodes the callback result into `CommandResponse::{ status, payload, error }`
///
/// If payload decoding fails, no handler exists, or the request shape is
/// invalid, the returned `CommandResponse` has `status == "error"`.
pub fn[Payload : @json.FromJson, Reply : ToJson] CommandBridge::handle(
  self : CommandBridge,
  name : String,
  callback : (Payload) -> Reply,
) -> Unit {
  self.handlers.set(name, fn(payload_json) {
    let payload : Result[Payload, _] = try? @json.from_json(payload_json)
    match payload {
      Ok(payload) => CommandResponse::ok(callback(payload))
      Err(err) => CommandResponse::error(err.to_string())
    }
  })
}

///|
/// Registers a typed command handler that can return explicit command errors.
///
/// Use this when the handler needs to reply with `Result[Reply, String]` rather
/// than treating every failure as a transport/runtime exception.
pub fn[Payload : @json.FromJson, Reply : ToJson] CommandBridge::handle_result(
  self : CommandBridge,
  name : String,
  callback : (Payload) -> Result[Reply, String],
) -> Unit {
  self.handlers.set(name, fn(payload_json) {
    let payload : Result[Payload, _] = try? @json.from_json(payload_json)
    match payload {
      Ok(payload) =>
        match callback(payload) {
          Ok(reply) => CommandResponse::ok(reply)
          Err(message) => CommandResponse::error(message)
        }
      Err(err) => CommandResponse::error(err.to_string())
    }
  })
}

///|
/// Emits a named command from MoonBit to JavaScript.
///
/// The JS dispatch is scheduled onto the webview event loop so this remains
/// safe to call off the UI thread.
///
/// This is a fire-and-forget notification API. It does not wait for a JS
/// response. JavaScript receives the command through
/// `window.MoonBitBridge.onCommand(listener)` as a `Command`-shaped object.
pub fn[Payload : ToJson] CommandBridge::send(
  self : CommandBridge,
  name : String,
  payload : Payload,
) -> Unit {
  let command = Command::{ name, payload: ToJson::to_json(payload) }
  let script = make_command_dispatch_script(
    self.global_name,
    self.event_name,
    command.to_json().stringify(),
  )
  self.webview.dispatch(fn() { self.webview.eval(script) })
}

///|
fn CommandBridge::respond(
  self : CommandBridge,
  id : String,
  response : CommandResponse,
) -> Unit {
  self.webview.response(id, 0, response.to_json().stringify())
}

///|
fn CommandBridge::handle_request(
  self : CommandBridge,
  raw_id : Bytes,
  raw_req : Bytes,
) -> Unit {
  let id = @ffi.from_cstr(raw_id)
  let response = match parse_command_request(@ffi.from_cstr(raw_req)) {
    Ok(command) =>
      match self.handlers.get(command.name) {
        Some(handler) => handler(command.payload)
        None => CommandResponse::error("Unknown command: " + command.name)
      }
    Err(message) => CommandResponse::error(message)
  }
  self.respond(id, response)
}

///|
fn parse_command_request(raw_req : String) -> Result[Command, String] {
  // A webview binding receives its JS arguments as a JSON array. The bridge
  // expects exactly one argument: the `{ name, payload }` command object.
  let request_json : Result[Json, _] = try? @json.parse(raw_req)
  match request_json {
    Err(err) => Err(err.to_string())
    Ok(request_json) => {
      let request_args : Result[Array[Command], _] = try? @json.from_json(
        request_json,
      )
      match request_args {
        Err(err) => Err(err.to_string())
        Ok(request_args) =>
          if request_args.length() == 1 {
            Ok(request_args[0])
          } else {
            Err("Expected exactly one command argument")
          }
      }
    }
  }
}

///|
fn make_command_bridge_script(
  global_name : String,
  binding_name : String,
  event_name : String,
) -> String {
  // Install a tiny JS runtime helper for request/reply (`send`) and
  // fire-and-forget native events (`onCommand`).
  let global_name_js = Json::string(global_name).stringify()
  let binding_name_js = Json::string(binding_name).stringify()
  let event_name_js = Json::string(event_name).stringify()
  "(function() {" +
  "  const globalName = " +
  global_name_js +
  ";" +
  "  const bindingName = " +
  binding_name_js +
  ";" +
  "  const eventName = " +
  event_name_js +
  ";" +
  "  function dispatch(command) {" +
  "    window.dispatchEvent(new CustomEvent(eventName, { detail: command }));" +
  "  }" +
  "  window[globalName] = {" +
  "    send: function(name, payload) {" +
  "      const command = { name: name, payload: payload === undefined ? null : payload };" +
  "      return window[bindingName](command);" +
  "    }," +
  "    onCommand: function(listener) {" +
  "      const handler = function(event) { listener(event.detail); };" +
  "      window.addEventListener(eventName, handler);" +
  "      return function() { window.removeEventListener(eventName, handler); };" +
  "    }," +
  "    __dispatchCommand: dispatch," +
  "    eventName: eventName" +
  "  };" +
  "})();"
}

///|
fn make_command_dispatch_script(
  global_name : String,
  event_name : String,
  command_json : String,
) -> String {
  // Reuse the injected helper when it exists so both directions share the
  // same event path. Fall back to dispatching the browser event directly.
  let global_name_js = Json::string(global_name).stringify()
  let event_name_js = Json::string(event_name).stringify()
  "(function() {" +
  "  const command = " +
  command_json +
  ";" +
  "  const bridge = window[" +
  global_name_js +
  "];" +
  "  if (bridge && bridge.__dispatchCommand) {" +
  "    bridge.__dispatchCommand(command);" +
  "    return;" +
  "  }" +
  "  window.dispatchEvent(new CustomEvent(" +
  event_name_js +
  ", { detail: command }));" +
  "})();"
}
