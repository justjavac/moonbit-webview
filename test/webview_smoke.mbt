///|
struct ExtensionNotice {
  message : String
} derive(ToJson, FromJson, Eq, Show)

///|
struct ExtensionNoticeEvent {
  extension : String
  name : String
  payload : ExtensionNotice
} derive(ToJson, FromJson, Eq, Show)

///|
struct MultiplyPayload {
  left : Int
  right : Int
} derive(ToJson, FromJson, Eq, Show)

///|
struct MultiplyReply {
  total : Int
} derive(ToJson, FromJson, Eq, Show)

///|
struct OpsRuntimeReport {
  direct : MultiplyReply
  extension : MultiplyReply
  event_count : Int
} derive(ToJson, FromJson, Eq, Show)

///|
struct AppRuntimeHelperReport {
  via_helper : MultiplyReply
  via_extension : MultiplyReply
  via_core : MultiplyReply
  event_count : Int
} derive(ToJson, FromJson, Eq, Show)

///|
fn[Payload : @json.FromJson] decode_single_argument(
  raw_req : Bytes,
) -> Result[Payload, String] {
  let request_json : Result[Json, _] = try? @json.parse(@ffi.from_cstr(raw_req))
  match request_json {
    Err(err) => Err(err.to_string())
    Ok(request_json) => {
      let request_args : Result[Array[Payload], _] = try? @json.from_json(
        request_json,
      )
      match request_args {
        Err(err) => Err(err.to_string())
        Ok(request_args) =>
          if request_args.length() == 1 {
            Ok(request_args[0])
          } else {
            Err("Expected exactly one argument")
          }
      }
    }
  }
}

///|
test "Start app loop and terminate it" {
  let webview = @webview.Webview::new()
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
  assert_eq(1 + 1, 2)
}

///|
test "Create a window, run app and terminate it" {
  let webview = @webview.Webview::new()
  webview.set_title("Test")
  webview.set_size(480, 320, @webview.SizeHint::None)
  webview.set_html("set_html ok")
  webview.navigate("data:text/plain,navigate%20ok")
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
}

///|
test "Bind callback marshals C strings safely" {
  let mut called = false
  let mut callback_id = ""
  let mut callback_req = ""
  let webview = @webview.Webview::new()
  webview.bind("press", fn(id, req) {
    callback_id = @ffi.from_cstr(id)
    callback_req = @ffi.from_cstr(req)
    called = true
    webview.response(callback_id, 0, "{\"ok\":true}")
    webview.terminate()
  })
  webview.set_html(
    (
      #| <html>
      #|   <body>
      #|     <script>
      #|       window.addEventListener("load", () => {
      #|         window.setTimeout(() => {
      #|           window.press("hello", 123).catch((error) => {
      #|             document.body.textContent = String(error);
      #|           });
      #|         }, 0);
      #|       });
      #|     </script>
      #|   </body>
      #| </html>,
    ),
  )
  webview.run()
  assert_true(called)
  assert_true(!callback_id.is_empty())
  assert_eq(callback_req, "[\"hello\",123]")
}

