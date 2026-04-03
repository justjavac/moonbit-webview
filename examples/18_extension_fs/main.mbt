///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  @runtime.install_extension(webview, @fs.extension())
  webview.set_title("MoonBit Filesystem Extension")
  webview.set_size(960, 720, @webview.SizeHint::None)
  webview.set_html(resource)
  webview.run()
}
