///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.install_plugin(@fs.plugin())
  webview.set_title("MoonBit Filesystem Plugin")
  webview.set_size(960, 720, @webview.SizeHint::None)
  webview.set_html(resource)
  webview.run()
}
