///|
/// Defines an HTML string containing a simple webpage with a JavaScript alert.
///
/// Contains a minimal HTML document structure with a script tag that displays an
/// alert message "Hello Moonbit!" when loaded.
let html =
  #| <html>
  #|   <body>
  #|     <script>alert("Hello Moonbit!")</script>
  #|   </body>
  #| </html>

///|
/// Creates and runs a webview window that displays a simple HTML page with a
/// JavaScript alert.
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.set_title("Moonbit Webview Example")
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.set_html(html)
  webview.run()
}
