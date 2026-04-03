///|
/// Defines the HTML template for the local webview example. Contains a centered
/// "Hello, Moonbit!" message with custom styling.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       :root {
  #|         color-scheme: light dark;
  #|         --bg: #f3efe7;
  #|         --ink: #1d2329;
  #|         --shadow: rgba(29, 35, 41, 0.1);
  #|       }
  #|       @media (prefers-color-scheme: dark) {
  #|         :root {
  #|           --bg: #0f151a;
  #|           --ink: #edf2f7;
  #|           --shadow: rgba(0, 0, 0, 0.36);
  #|         }
  #|       }
  #|       body {
  #|         display: flex;
  #|         align-items: center;
  #|         justify-content: center;
  #|         height: 100vh;
  #|         margin: 0;
  #|         font-size: 3.75rem;
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|         background:
  #|           radial-gradient(circle at top, rgba(15, 118, 110, 0.14), transparent 32%),
  #|           radial-gradient(circle at bottom right, rgba(217, 119, 6, 0.14), transparent 34%),
  #|           var(--bg);
  #|         color: var(--ink);
  #|         text-shadow: 0 10px 30px var(--shadow);
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
  .run()
}
