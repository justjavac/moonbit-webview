///|
priv struct OpRegistry {
  handlers : Map[String, (Json) -> Result[Json, String]]
}

///|
fn OpRegistry::new() -> OpRegistry {
  OpRegistry::{ handlers: {} }
}

///|
fn[Payload : @json.FromJson, Reply : ToJson] OpRegistry::handle(
  self : OpRegistry,
  name : String,
  callback : (Payload) -> Reply,
) -> Unit {
  self.handle_result(name, fn(payload) { Ok(callback(payload)) })
}

///|
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
    match payload {
      Ok(payload) =>
        match callback(payload) {
          Ok(reply) => Ok(ToJson::to_json(reply))
          Err(message) => Err(message)
        }
      Err(err) => Err(err.to_string())
    }
  })
}

///|
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

///|
