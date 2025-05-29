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
/// Creates and runs a webview window displaying a local HTML content with a
/// "Hello, Moonbit!" message.
///
/// The webview window is configured with:
///
/// * Debug mode enabled
/// * Custom title "Moonbit Webview Example"
/// * Window size of 800x600 pixels
/// * Centered text content with custom styling
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  ..run()
}
