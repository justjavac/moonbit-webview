///|
/// A named command exchanged between JavaScript and MoonBit.
pub struct Command {
  name : String
  payload : Json
} derive(ToJson, FromJson, Show, Eq)

///|
/// High-level JSON command bridge built on top of `webview.bind()`.
///
/// It injects a JS helper object into the page and routes named commands to
/// registered MoonBit handlers.
struct CommandBridge {
  webview : Webview
  global_name : String
  event_name : String
  handlers : Map[String, (Json) -> Result[Json, String]]
}

///|
/// Creates and installs a command bridge for the given webview.
///
/// On the JavaScript side this exposes `window[global_name].send(name, payload)`
/// and `window[global_name].onCommand(listener)`.
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
pub fn[Payload : @json.FromJson, Reply : ToJson] CommandBridge::handle(
  self : CommandBridge,
  name : String,
  callback : (Payload) -> Reply,
) -> Unit {
  self.handlers.set(name, fn(payload_json) {
    let payload : Result[Payload, _] = try? @json.from_json(payload_json)
    match payload {
      Ok(payload) => Ok(ToJson::to_json(callback(payload)))
      Err(err) => Err(err.to_string())
    }
  })
}

///|
/// Emits a named command from MoonBit to JavaScript.
///
/// The JS dispatch is scheduled onto the webview event loop so this remains
/// safe to call off the UI thread.
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
fn CommandBridge::respond_error(
  self : CommandBridge,
  id : String,
  message : String,
) -> Unit {
  self.webview.response(id, 1, Json::string(message).stringify())
}

///|
fn CommandBridge::handle_request(
  self : CommandBridge,
  raw_id : Bytes,
  raw_req : Bytes,
) -> Unit {
  let id = @ffi.from_cstr(raw_id)
  match parse_command_request(@ffi.from_cstr(raw_req)) {
    Ok(command) =>
      match self.handlers.get(command.name) {
        Some(handler) =>
          match handler(command.payload) {
            Ok(result) => self.webview.response(id, 0, result.stringify())
            Err(message) => self.respond_error(id, message)
          }
        None => self.respond_error(id, "Unknown command: " + command.name)
      }
    Err(message) => self.respond_error(id, message)
  }
}

///|
fn parse_command_request(raw_req : String) -> Result[Command, String] {
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
