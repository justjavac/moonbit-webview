struct PingPayload {
  message : String
  count : Int
} derive(ToJson, FromJson, Eq, Show)

struct PingReply {
  echoed : String
  next_count : Int
} derive(ToJson, FromJson, Eq, Show)

struct NativeEvent {
  label : String
  total : Int
} derive(ToJson, FromJson, Eq, Show)

///|
test "Start app loop and terminate it" {
  let webview = @webview.Webview::new()
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
  assert_eq(1 + 1, 2)
  assert_eq(2 + 2, 4)
}

///|
test "Create a window, run app and terminate it" {
  let webview = @webview.Webview::new()
  webview.set_title("Test")
  webview.set_size(480, 320, @webview.SizeHint::None)
  webview.set_html("set_html ok")
  webview.navigate("data:text/plain,navigate%20ok")
  webview.dispatch(fn() {  })
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
      #|       window.onload = () => {
      #|         window.press("hello", 123).catch((error) => {
      #|           document.body.textContent = String(error);
      #|         });
      #|       };
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

///|
test "Command bridge exchanges typed commands with JavaScript" {
  let expected_ping = PingPayload::{ message: "hello from js", count: 3 }
  let expected_reply = PingReply::{
    echoed: "hello from js / handled by MoonBit",
    next_count: 4,
  }
  let expected_event = NativeEvent::{ label: "native-ready", total: 6 }
  let mut seen_ping : PingPayload? = None
  let mut seen_reply : PingReply? = None
  let mut seen_event : NativeEvent? = None
  let webview = @webview.Webview::new()
  let bridge = @webview.CommandBridge::new(webview)
  let finish = fn() {
    if seen_reply is Some(_) && seen_event is Some(_) {
      webview.terminate()
    }
  }
  bridge.handle("ping", fn(payload : PingPayload) {
    seen_ping = Some(payload)
    bridge.send("nativeEvent", expected_event)
    expected_reply
  })
  bridge.handle("jsResult", fn(payload : PingReply) {
    seen_reply = Some(payload)
    finish()
  })
  bridge.handle("jsObservedNativeEvent", fn(payload : NativeEvent) {
    seen_event = Some(payload)
    finish()
  })
  webview.set_html(
    (
      #| <html>
      #|   <body>
      #|     <script>
      #|       window.addEventListener("load", () => {
      #|         const bridge = window.MoonBitBridge;
      #|         bridge.onCommand((command) => {
      #|           if (command.name === "nativeEvent") {
      #|             bridge
      #|               .send("jsObservedNativeEvent", command.payload)
      #|               .catch((error) => {
      #|                 document.body.textContent = "nativeEvent error: " + String(error);
      #|               });
      #|           }
      #|         });
      #|         bridge
      #|           .send("ping", { message: "hello from js", count: 3 })
      #|           .then((result) => bridge.send("jsResult", result))
      #|           .catch((error) => {
      #|             document.body.textContent = "ping error: " + String(error);
      #|           });
      #|       });
      #|     </script>
      #|   </body>
      #| </html>,
    ),
  )
  webview.run()
  assert_eq(seen_ping, Some(expected_ping))
  assert_eq(seen_reply, Some(expected_reply))
  assert_eq(seen_event, Some(expected_event))
}
