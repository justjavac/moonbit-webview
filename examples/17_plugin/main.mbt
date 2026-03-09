///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.install_plugin(plugin())
  webview.set_title("MoonBit Plugin API")
  webview.set_size(900, 640, @webview.SizeHint::None)
  webview.set_html(resource)
  webview.run()
}
