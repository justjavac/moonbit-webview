///|
/// Creates and runs a webview window displaying a local HTML content with a
/// "Hello, Moonbit!" message.
///
/// The webview window is configured with:
///
/// * Debug mode enabled
/// * Custom title "Moonbit Webview Example"
/// * Window size of 800x600 pixels
/// * Centered text content with custom styling
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(resource)
  ..run()
}
