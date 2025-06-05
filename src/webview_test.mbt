///|
test "Start app loop and terminate it" {
  let webview = @webview.Webview::new()
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
  assert_eq!(1 + 1, 2)
  assert_eq!(2 + 2, 4)
}
