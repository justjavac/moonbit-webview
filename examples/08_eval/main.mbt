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
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  ..run()
  ..eval("foo('Hello from Moonbit!');")
}
