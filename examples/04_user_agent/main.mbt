///|
/// Defines an HTML template that displays the user agent string of the browser.
/// 
/// This example demonstrates how to create a simple webview application that
/// displays the user agent string of the browser in a styled HTML document.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       body {
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <script>document.body.innerHTML = window.navigator.userAgent; </script>
  #|   </body>
  #| </html>

///|
/// Creates and runs a webview window that displays the user agent string of the
/// browser.
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  ..run()
}
