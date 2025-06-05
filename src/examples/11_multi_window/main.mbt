///|
/// Defines the HTML template for the local webview example. Contains a centered
/// "Hello, Moonbit!" message with custom styling.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       body {
  #|         display: flex;
  #|         align-items: center;
  #|         justify-content: center;
  #|         height: 100vh;
  #|         margin: 0;
  #|         font-size: 3.75rem;
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     Hello, Moonbit!
  #|   </body>
  #| </html>

///|
/// Creates and runs two webview windows displaying a local HTML content with a
/// "Hello, Moonbit!" message.
fn main {
  let webview1 = @webview.Webview::new(debug=1);
  webview1.set_title("Moonbit Webview Example");
  webview1.set_size(800, 600, @webview.SizeHint::None);
  webview1.set_html(html);

  let webview2 = @webview.Webview::new(debug=1);
  webview2.set_title("Moonbit Webview Example");
  webview2.set_size(800, 600, @webview.SizeHint::None);
  webview2.set_html(html);

  webview1.run();
  webview2.run();
}
