///|
let html =
  #| <html>
  #|   <body>
  #|     <h1>Hello, Moonbit!</h1>
  #|     <button type="submit" onclick="press('I was pressed!', 123, new Date()).then(console.log);">
  #|        Press me!
  #|      </button>
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
