///|
/// Defines an HTML template that displays the user agent string of the browser.
/// 
/// This example demonstrates how to create a simple webview application that
/// displays the user agent string of the browser in a styled HTML document.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       :root {
  #|         color-scheme: light dark;
  #|         --bg: #f4efe7;
  #|         --panel: rgba(255, 252, 247, 0.94);
  #|         --line: rgba(24, 32, 40, 0.1);
  #|         --ink: #182028;
  #|         --shadow: rgba(24, 32, 40, 0.12);
  #|       }
  #|       @media (prefers-color-scheme: dark) {
  #|         :root {
  #|           --bg: #0f151a;
  #|           --panel: rgba(18, 27, 35, 0.92);
  #|           --line: rgba(198, 216, 231, 0.14);
  #|           --ink: #ecf2f7;
  #|           --shadow: rgba(0, 0, 0, 0.36);
  #|         }
  #|       }
  #|       body {
  #|         margin: 0;
  #|         min-height: 100vh;
  #|         display: grid;
  #|         place-items: center;
  #|         padding: 24px;
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|         background:
  #|           radial-gradient(circle at top left, rgba(15, 118, 110, 0.14), transparent 34%),
  #|           radial-gradient(circle at bottom right, rgba(180, 83, 9, 0.12), transparent 36%),
  #|           var(--bg);
  #|         color: var(--ink);
  #|       }
  #|       .ua {
  #|         width: min(48rem, 100%);
  #|         padding: 20px 22px;
  #|         border: 1px solid var(--line);
  #|         border-radius: 20px;
  #|         background: var(--panel);
  #|         box-shadow: 0 24px 70px var(--shadow);
  #|         line-height: 1.7;
  #|         word-break: break-word;
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <div class="ua"></div>
  #|     <script>document.querySelector('.ua').textContent = window.navigator.userAgent; </script>
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
  .run()
}
