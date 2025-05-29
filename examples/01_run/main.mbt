///|
/// Creates and runs a webview window with debug mode enabled.
///
/// Sets up a webview window with the following configurations:
///
/// * Debug mode is enabled
/// * Window size is set to 800x600 pixels
/// * No size hint constraints
fn main {
  @webview.Webview::new(debug=1)
  ..set_size(800, 600, @webview.SizeHint::None)
  ..run()
}
