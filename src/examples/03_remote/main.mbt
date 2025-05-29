///|
/// Creates and runs a webview window that navigates to the MoonBit homepage.
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..navigate("https://www.moonbitlang.com")
  ..run()
}
