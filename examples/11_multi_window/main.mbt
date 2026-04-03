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
/// Creates and runs two webview windows displaying a local HTML content with a
/// "Hello, Moonbit!" message.
fn main {
  let webview1 = @webview.Webview::new(debug=1)
  webview1.set_title("Moonbit Webview Example")
  webview1.set_size(800, 600, @webview.SizeHint::None)
  webview1.set_html(html)
  let webview2 = @webview.Webview::new(debug=1)
  webview2.set_title("Moonbit Webview Example")
  webview2.set_size(800, 600, @webview.SizeHint::None)
  webview2.set_html(html)
  webview1.run()
  webview2.run()
}
