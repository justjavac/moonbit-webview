///|
test "Webview::emit_extension delivers events to JavaScript listeners" {
  let expected_event = ExtensionNoticeEvent::{
    extension: "math",
    name: "computed",
    payload: ExtensionNotice::{ message: "MoonBit extension emitted 42" },
  }
  let mut seen_event : ExtensionNoticeEvent? = None
  let mut js_error : String? = None
  let webview = @webview.Webview::new()
  @lepus_core.install_extension(
    webview,
    @lepus_core.Extension::new("tests/math", "math", fn(_extension) {  }),
  )
  webview.bind("reportExtensionFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some(
          "Failed to decode extension failure payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportExtensionEvent", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let event_result : Result[ExtensionNoticeEvent, String] = decode_single_argument(
      req,
    )
    match event_result {
      Ok(event) => seen_event = Some(event)
      Err(message) =>
        js_error = Some("Failed to decode extension event payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("requestNativeExtensionEvent", fn(id, _req) {
    let request_id = @ffi.from_cstr(id)
    @lepus_core.emit_extension(webview, "math", "computed", ExtensionNotice::{
      message: "MoonBit extension emitted 42",
    })
    webview.response(request_id, 0, "null")
  })
  webview.set_html(
    (
      #| <html>
      #|   <body>
      #|     <script>
      #|       const reportFailure = (message) =>
      #|         window.reportExtensionFailure(message).catch(() => {});
      #|       const waitFor = (predicate, onReady, label, attempts = 0) => {
      #|         if (predicate()) {
      #|           onReady();
      #|           return;
      #|         }
      #|         if (attempts >= 50) {
      #|           void reportFailure(label + " timeout");
      #|           return;
      #|         }
      #|         window.setTimeout(() => {
      #|           waitFor(predicate, onReady, label, attempts + 1);
      #|         }, 20);
      #|       };
      #|       window.addEventListener("error", (event) => {
      #|         void reportFailure("window error: " + String(event.message));
      #|       });
      #|       window.addEventListener("unhandledrejection", (event) => {
      #|         void reportFailure("unhandled rejection: " + String(event.reason));
      #|       });
      #|       window.addEventListener("load", () => {
      #|         waitFor(
      #|           () => {
      #|             const moonbit = window.__MoonBit__;
      #|             return !!moonbit && !!moonbit.events;
      #|           },
      #|           () => {
      #|             const moonbit = window.__MoonBit__;
      #|             const timeoutId = window.setTimeout(() => {
      #|               void reportFailure("emit_extension listener timeout");
      #|             }, 1000);
      #|             moonbit.events.on("math.computed", (event) => {
      #|               window.clearTimeout(timeoutId);
      #|               void window.reportExtensionEvent(event).catch(() => {});
      #|             });
      #|             window.setTimeout(() => {
      #|               window.requestNativeExtensionEvent().catch((error) => {
      #|                 window.clearTimeout(timeoutId);
      #|                 void reportFailure("emit_extension transport error: " + String(error));
      #|               });
      #|             }, 0);
      #|           },
      #|           "extension runtime",
      #|         );
      #|       });
      #|     </script>
      #|   </body>
      #| </html>,
    ),
  )
  webview.run()
  assert_true(seen_event == Some(expected_event))
  assert_eq(js_error, None)
}
