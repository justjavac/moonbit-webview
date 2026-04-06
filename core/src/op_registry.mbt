///|
priv struct OpRegistry {
  handlers : Map[String, (Json) -> Result[Json, String]]
}

///|
/// Creates an empty op handler registry.
fn OpRegistry::new() -> OpRegistry {
  OpRegistry::{ handlers: {} }
}

///|
/// Registers a typed op handler that cannot fail explicitly.
fn[Payload : @json.FromJson, Reply : ToJson] OpRegistry::handle(
  self : OpRegistry,
  name : String,
  callback : (Payload) -> Reply,
) -> Unit {
  self.handle_result(name, fn(payload) { Ok(callback(payload)) })
}

///|
/// Registers a typed op handler that can return a string error.
fn[Payload : @json.FromJson, Reply : ToJson] OpRegistry::handle_result(
  self : OpRegistry,
  name : String,
  callback : (Payload) -> Result[Reply, String],
) -> Unit {
  guard self.handlers.get(name) is None else {
    abort("OpRegistry::handle_result: op already registered: " + name)
  }
  self.handlers.set(name, fn(payload_json) {
    let payload : Result[Payload, _] = try? @json.from_json(payload_json)
    payload
    .map_err(fn(err) { err.to_string() })
    .bind(callback)
    .map(fn(reply) { ToJson::to_json(reply) })
  })
}

///|
/// Invokes a previously registered op handler with raw JSON payload.
fn OpRegistry::call(
  self : OpRegistry,
  name : String,
  payload : Json,
) -> Result[Json, String] {
  match self.handlers.get(name) {
    Some(handler) => handler(payload)
    None => Err("Unknown op: " + name)
  }
}
