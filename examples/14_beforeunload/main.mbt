///|
/// Defines an HTML template that displays "Hello, Moonbit!" in the center of the
/// window.
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
  #|     <div>Hello, Moonbit!</div>
  #|     <script>
  #|       addEventListener("beforeunload", (event) => {
  #|         // Cancel the event as stated by the standard.
  #|         event.preventDefault();
  #|         // Chrome requires returnValue to be set.
  #|         event.returnValue = "";
  #|       });
  #|     </script>
  #|   </body>
  #| </html>

///|
/// Creates a window with "Hello, Moonbit!" displayed in the center using a
/// customized HTML template.
/// 
/// This example demonstrates how to use the `beforeunload` event to change the
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  .run()
}
