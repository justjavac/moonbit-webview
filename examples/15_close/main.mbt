///|
/// Defines the HTML template for the close example.
/// 
/// This HTML includes a button that, when pressed, closes the webview.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       :root {
  #|         color-scheme: light dark;
  #|         --bg: #f4efe7;
  #|         --ink: #182028;
  #|         --button: #0f766e;
  #|         --button-text: #f8fffd;
  #|       }
  #|       @media (prefers-color-scheme: dark) {
  #|         :root {
  #|           --bg: #0f151a;
  #|           --ink: #ecf2f7;
  #|           --button: #34d399;
  #|           --button-text: #072018;
  #|         }
  #|       }
  #|       body {
  #|         display: flex;
  #|         flex-direction: column;
  #|         align-items: center;
  #|         justify-content: center;
  #|         height: 100vh;
  #|         margin: 0;
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|         background:
  #|           radial-gradient(circle at top, rgba(15, 118, 110, 0.14), transparent 32%),
  #|           radial-gradient(circle at bottom right, rgba(217, 119, 6, 0.14), transparent 34%),
  #|           var(--bg);
  #|         color: var(--ink);
  #|       }
  #|       button {
  #|         font-size: 1.5rem;
  #|         cursor: pointer;
  #|         padding: 10px 20px;
  #|         background-color: var(--button);
  #|         color: var(--button-text);
  #|         border: none;
  #|         border-radius: 5px;
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <h1>Hello, Moonbit!</h1>
  #|     <button onclick="close()">
  #|        Close Webview
  #|     </button>
  #|   </body>
  #| </html>

///|
/// Creates and runs a webview window that displays a button.
/// When the button is pressed, the webview will close.
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("MoonBit Lepus Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  .run()
}
