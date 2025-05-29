///|
/// Creates and runs a webview window with debug mode enabled.
///
/// Sets up a webview window with the following configurations:
///
/// * Debug mode is enabled
/// * Window size is set to 800x600 pixels
/// * No size hint constraints
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.run()
}
