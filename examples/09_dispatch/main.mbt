///|
/// Defines an HTML template that displays a simple message in the webview.
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
  #|         font-size: 2.4rem;
  #|       }
  #|     </style>
  #|   </head>
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
  let webview = @webview.Webview::new(debug=1)
  webview.set_title("Moonbit Webview Example")
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.set_html(html)
  webview.dispatch(fn() { webview.terminate() })
  webview.run()
}
