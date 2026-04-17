///|
/// Defines the HTML template for the bind example.
/// 
/// This HTML includes a button that, when pressed, calls a JavaScript function
/// `press` with a message, a number, and the current date.
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
  #|         --panel: #f3f5f7;
  #|         --line: rgba(24, 32, 40, 0.1);
  #|       }
  #|       @media (prefers-color-scheme: dark) {
  #|         :root {
  #|           --bg: #0f151a;
  #|           --ink: #ecf2f7;
  #|           --button: #34d399;
  #|           --button-text: #072018;
  #|           --panel: #111a22;
  #|           --line: rgba(198, 216, 231, 0.14);
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
  #|       pre {
  #|         max-width: 40rem;
  #|         margin-top: 1rem;
  #|         padding: 1rem;
  #|         border-radius: 8px;
  #|         border: 1px solid var(--line);
  #|         background: var(--panel);
  #|         white-space: pre-wrap;
  #|       }
  #|     </style>
  #|     <script>
  #|       function log(result) {
  #|         document.getElementById('output').textContent =
  #|           JSON.stringify(result, null, 2);
  #|       }
  #|       function logError(error) {
  #|         document.getElementById('output').textContent = String(error);
  #|       }
  #|     </script>
  #|   </head>
  #|   <body>
  #|     <h1>Hello, Moonbit!</h1>
  #|     <button onclick="window.press('I was pressed!', 123, new Date().toISOString()).then(log).catch(logError);">
  #|        Press me!
  #|     </button>
  #|     <pre id="output">Click the button to call MoonBit.</pre>
  #|   </body>
  #| </html>

///|
/// Creates and runs a webview window that displays a button.
/// When the button is pressed, it calls the `press` function with a message,
/// a number, and the current date.
fn main {
  let mut counter = 0
  let webview = @webview.Webview::new(debug=1)
  webview.set_title("MoonBit Lepus Example")
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.bind("press", fn(id, req) {
    counter += 1
    let id = @ffi.from_cstr(id)
    let req = @ffi.from_cstr(req)
    let result = "{\"message\":\"Handled by MoonBit\",\"count\": " +
      counter.to_string() +
      ", \"args\": " +
      req +
      "}"
    println(id)
    println(req)
    println(counter)
    webview.response(id, 0, result)
  })
  webview.set_html(html)
  webview.run()
}
