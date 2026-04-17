///|
/// Defines an HTML string containing a simple webpage with a JavaScript alert.
///
/// Contains a minimal HTML document structure with a script tag that displays an
/// alert message "Hello Moonbit!" when loaded.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       :root {
  #|         color-scheme: light dark;
  #|         --bg: #f4efe7;
  #|         --ink: #182028;
  #|       }
  #|       @media (prefers-color-scheme: dark) {
  #|         :root {
  #|           --bg: #0f151a;
  #|           --ink: #ecf2f7;
  #|         }
  #|       }
  #|       body {
  #|         margin: 0;
  #|         min-height: 100vh;
  #|         display: grid;
  #|         place-items: center;
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|         background:
  #|           radial-gradient(circle at top, rgba(15, 118, 110, 0.14), transparent 32%),
  #|           var(--bg);
  #|         color: var(--ink);
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <p>Alert demo is running.</p>
  #|     <script>alert("Hello Moonbit!")</script>
  #|   </body>
  #| </html>

///|
/// Creates and runs a webview window that displays a simple HTML page with a
/// JavaScript alert.
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("MoonBit Lepus Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  .run()
}
