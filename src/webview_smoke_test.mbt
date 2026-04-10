///|
test "Start app loop and terminate it" {
  let webview = @lepus.Webview::new()
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
  assert_eq(1 + 1, 2)
}

///|
test "Create a window, run app and terminate it" {
  let webview = @lepus.Webview::new()
  webview.set_title("Test")
  webview.set_size(480, 320, @lepus.SizeHint::None)
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
  let webview = @lepus.Webview::new()
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
