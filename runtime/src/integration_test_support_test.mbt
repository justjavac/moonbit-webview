///|
struct ExtensionNotice {
  message : String
} derive(ToJson, FromJson, Eq, Debug)

///|
struct ExtensionNoticeEvent {
  extension : String
  name : String
  payload : ExtensionNotice
} derive(ToJson, FromJson, Eq, Debug)

///|
struct MultiplyPayload {
  left : Int
  right : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
struct MultiplyReply {
  total : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
struct AppRuntimeHelperReport {
  via_invoke : MultiplyReply
  via_method : MultiplyReply
  via_core : MultiplyReply
  event_count : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
/// Decodes the single callback argument payload used by the runtime integration tests.
fn[Payload : @json.FromJson] decode_single_argument(
  raw_req : Bytes,
) -> Result[Payload, String] {
  let request_json : Result[Json, _] = try? @json.parse(@ffi.from_cstr(raw_req))
  request_json
  .map_err(fn(err) { err.to_string() })
  .bind(fn(request_json) {
    let request_args : Result[Array[Payload], _] = try? @json.from_json(
      request_json,
    )
    request_args
    .map_err(fn(err) { err.to_string() })
    .bind(expect_single_argument)
  })
}

///|
/// Ensures the callback bridge supplied exactly one typed argument.
fn[Payload] expect_single_argument(
  request_args : Array[Payload],
) -> Result[Payload, String] {
  if request_args.length() == 1 {
    Ok(request_args[0])
  } else {
    Err("Expected exactly one argument")
  }
}
