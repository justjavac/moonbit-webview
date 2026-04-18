///|
struct JsonPayload {
  size : Int
  payload : String
} derive(ToJson, FromJson, Eq, Debug)

///|
struct JsonAck {
  ok : Bool
  size : Int
  payload_length : Int
  raw_request_length : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
struct SharedBufferRequest {
  size : Int
  sequence : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
struct NativeStatus {
  ok : Bool
  status : Int
  message : String
} derive(ToJson, FromJson, Eq, Debug)

///|
struct SharedBufferCapabilities {
  is_windows : Bool
  has_controller : Bool
  has_core_webview : Bool
  has_webview2_17 : Bool
  has_environment12 : Bool
  can_create_shared_buffer : Bool
  supported : Bool
  last_error : String
} derive(ToJson, FromJson, Eq, Debug)

///|
struct GeneratedPayload {
  payload : Bytes
  checksum : Int
}

///|
fn[Payload : @json.FromJson] decode_single_argument(
  raw_req : Bytes,
) -> Result[Payload, String] {
  decode_arguments(raw_req).bind(fn(request_args) {
    if request_args.length() == 1 {
      Ok(request_args[0])
    } else {
      Err("Expected exactly one argument")
    }
  })
}

///|
fn[Payload : @json.FromJson] decode_arguments(
  raw_req : Bytes,
) -> Result[Array[Payload], String] {
  let request_json : Result[Json, _] = try? @json.parse(@ffi.from_cstr(raw_req))
  request_json
  .map_err(fn(err) { err.to_string() })
  .bind(fn(request_json) {
    let request_args : Result[Array[Payload], _] = try? @json.from_json(
      request_json,
    )
    request_args.map_err(fn(err) { err.to_string() })
  })
}

///|
extern "C" fn shared_buffer_probe_ffi(controller : Int64) -> Int = "lepus_example_shared_buffer_probe"

///|
#borrow(payload)
extern "C" fn shared_buffer_publish_bytes_ffi(
  controller : Int64,
  payload : Bytes,
  size : Int,
  sequence : Int,
  checksum : Int,
) -> Int = "lepus_example_shared_buffer_publish_bytes"

///|
extern "C" fn shared_buffer_release_last_ffi() -> Unit = "lepus_example_shared_buffer_release_last"

///|
extern "C" fn shared_sum_prepare_ffi(controller : Int64) -> Int = "lepus_example_shared_sum_prepare"

///|
extern "C" fn shared_sum_read_x_ffi() -> Int = "lepus_example_shared_sum_read_x"

///|
extern "C" fn shared_sum_read_y_ffi() -> Int = "lepus_example_shared_sum_read_y"

///|
extern "C" fn shared_sum_write_result_ffi(result : Int) -> Int = "lepus_example_shared_sum_write_result"

///|
extern "C" fn shared_buffer_last_error_ffi() -> Bytes = "lepus_example_shared_buffer_last_error"

///|
fn shared_buffer_last_error() -> String {
  @ffi.from_cstr(shared_buffer_last_error_ffi())
}

///|
fn mask_has(mask : Int, bit : Int) -> Bool {
  mask / bit % 2 == 1
}

///|
fn sum(x : Int, y : Int) -> Int {
  x + y
}

///|
fn generate_payload(size : Int, sequence : Int) -> GeneratedPayload {
  let payload = FixedArray::make(size, b'\x00')
  let mut checksum = 0
  for index in 0..<size {
    let value = (index * 31 + sequence) & 0xff
    payload[index] = value.to_byte()
    checksum = checksum + value
  }
  GeneratedPayload::{ payload: payload.unsafe_reinterpret_as_bytes(), checksum }
}

///|
fn shared_buffer_capabilities(controller : Int64) -> SharedBufferCapabilities {
  let mask = shared_buffer_probe_ffi(controller)
  let has_webview2_17 = mask_has(mask, 8)
  let has_environment12 = mask_has(mask, 16)
  let can_create_shared_buffer = mask_has(mask, 32)
  SharedBufferCapabilities::{
    is_windows: mask_has(mask, 1),
    has_controller: mask_has(mask, 2),
    has_core_webview: mask_has(mask, 4),
    has_webview2_17,
    has_environment12,
    can_create_shared_buffer,
    supported: has_webview2_17 && has_environment12 && can_create_shared_buffer,
    last_error: shared_buffer_last_error(),
  }
}

///|
fn respond_json_error(
  webview : @webview.Webview,
  request_id : String,
  message : String,
) -> Unit {
  webview.response(request_id, 1, Json::string(message).stringify())
}

///|
fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new("SharedBuffer Benchmark", 1080, 760),
    @manifest.AppEntry::Asset("32_shared_buffer_benchmark/index.html"),
    debug=1,
  )
  let app : @wvrt.App = match
    @app.create_app(manifest, @app.ExtensionRegistry::new()) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  let webview : @webview.Webview = app.webview()
  let controller = webview.get_native_handle(@webview.NativeHandleKind::Browser)
  let mut report : Json? = None
  let mut js_error : String? = None
  webview.bind("probeSharedBuffer", fn(id, _req) {
    let request_id = @ffi.from_cstr(id)
    let capabilities = shared_buffer_capabilities(controller)
    webview.response(request_id, 0, capabilities.to_json().stringify())
  })
  webview.bind("sumJson", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let args_result : Result[Array[Int], String] = decode_arguments(req)
    match args_result {
      Ok(args) =>
        if args.length() == 2 {
          let result = sum(args[0], args[1])
          webview.response(request_id, 0, result.to_string())
        } else {
          respond_json_error(
            webview, request_id, "Expected exactly two arguments",
          )
        }
      Err(message) => respond_json_error(webview, request_id, message)
    }
  })
  webview.bind("prepareSharedSumBuffer", fn(id, _req) {
    let request_id = @ffi.from_cstr(id)
    let status = shared_sum_prepare_ffi(controller)
    if status == 0 {
      webview.response(request_id, 0, "0")
    } else {
      respond_json_error(webview, request_id, shared_buffer_last_error())
    }
  })
  webview.bind("sumSharedBuffer", fn(id, _req) {
    let request_id = @ffi.from_cstr(id)
    let x = shared_sum_read_x_ffi()
    let y = shared_sum_read_y_ffi()
    let status = shared_sum_write_result_ffi(sum(x, y))
    if status == 0 {
      webview.response(request_id, 0, "0")
    } else {
      respond_json_error(webview, request_id, shared_buffer_last_error())
    }
  })
  webview.bind("benchmarkJsonPayload", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let raw_request = @ffi.from_cstr(req)
    let payload_result : Result[JsonPayload, String] = decode_single_argument(
      req,
    )
    match payload_result {
      Ok(payload) => {
        let actual_length = payload.payload.length()
        if actual_length == payload.size {
          let ack = JsonAck::{
            ok: true,
            size: payload.size,
            payload_length: actual_length,
            raw_request_length: raw_request.length(),
          }
          webview.response(request_id, 0, ack.to_json().stringify())
        } else {
          respond_json_error(
            webview,
            request_id,
            "JSON payload length mismatch: expected " +
            payload.size.to_string() +
            ", got " +
            actual_length.to_string(),
          )
        }
      }
      Err(message) => respond_json_error(webview, request_id, message)
    }
  })
  webview.bind("requestSharedBuffer", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let request_result : Result[SharedBufferRequest, String] = decode_single_argument(
      req,
    )
    match request_result {
      Ok(request) => {
        let generated = generate_payload(request.size, request.sequence)
        let status = shared_buffer_publish_bytes_ffi(
          controller,
          generated.payload,
          request.size,
          request.sequence,
          generated.checksum,
        )
        let message = shared_buffer_last_error()
        if status == 0 {
          let ack = NativeStatus::{ ok: true, status, message }
          webview.response(request_id, 0, ack.to_json().stringify())
        } else {
          respond_json_error(webview, request_id, message)
        }
      }
      Err(message) => respond_json_error(webview, request_id, message)
    }
  })
  webview.bind("releaseSharedBuffer", fn(id, _req) {
    let request_id = @ffi.from_cstr(id)
    shared_buffer_release_last_ffi()
    let ack = NativeStatus::{ ok: true, status: 0, message: "released" }
    webview.response(request_id, 0, ack.to_json().stringify())
  })
  webview.bind("reportSharedBufferBenchmarkFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    let message = match message_result {
      Ok(message) => message
      Err(error) => "Failed to decode benchmark failure payload: " + error
    }
    js_error = Some(message)
    println("[shared-buffer-benchmark] JS failure: " + message)
    shared_buffer_release_last_ffi()
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportSharedBufferBenchmark", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let report_result : Result[Json, String] = decode_single_argument(req)
    match report_result {
      Ok(value) => {
        report = Some(value)
        println("[shared-buffer-benchmark] received report")
        println(value.stringify())
      }
      Err(message) => {
        let diagnostic = "Failed to decode benchmark report payload: " + message
        js_error = Some(diagnostic)
        println("[shared-buffer-benchmark] " + diagnostic)
      }
    }
    shared_buffer_release_last_ffi()
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  app.run()
  shared_buffer_release_last_ffi()
  match report {
    Some(_) => ()
    None =>
      match js_error {
        Some(message) => abort(message)
        None => abort("SharedBuffer benchmark exited without a report")
      }
  }
}
