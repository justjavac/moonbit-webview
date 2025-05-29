///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.run()
}
