///|
let html =
  #| <html>
  #|   <body>
  #|     <script>alert("Hello Moonbit!")</script>
  #|   </body>
  #| </html>

///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.set_title("Moonbit Webview Example")
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.set_html(html)
  webview.run()
}
