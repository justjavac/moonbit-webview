///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  @runtime.install_extension(webview, extension())
  webview.set_title("MoonBit Extension Runtime")
  webview.set_size(900, 640, @webview.SizeHint::None)
  webview.set_html(resource)
  webview.run()
}
