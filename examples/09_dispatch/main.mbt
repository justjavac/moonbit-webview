///|
/// Defines an HTML template that displays a simple message in the webview.
let html =
  #| <html>
  #|   <body>
  #|     <script>
  #|       function foo(msg) {
  #|         document.body.innerHTML = msg; 
  #|       }
  #|     </script>
  #|   </body>
  #| </html>

///|
/// Creates and runs a webview window that displays a message and injects JavaScript
/// to set a global variable.
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.set_title("Moonbit Webview Example")
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.set_html(html)
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
}
