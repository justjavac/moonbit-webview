///|
test "Start app loop and terminate it" {
  let webview = @webview.Webview::new()
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
  assert_eq!(1 + 1, 2)
  assert_eq!(2 + 2, 4)
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
  webview.destroy()
}
