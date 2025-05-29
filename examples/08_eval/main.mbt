///|
/// Defines an HTML template that displays a simple message by executing JavaScript
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
/// Creates and runs a webview window that evaluates JavaScript
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  ..eval("foo('Hello from Moonbit!');")
  ..run()
}
