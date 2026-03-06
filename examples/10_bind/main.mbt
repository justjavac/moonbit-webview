///|
/// Defines the HTML template for the bind example.
/// 
/// This HTML includes a button that, when pressed, calls a JavaScript function
/// `press` with a message, a number, and the current date.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       body {
  #|         display: flex;
  #|         flex-direction: column;
  #|         align-items: center;
  #|         justify-content: center;
  #|         height: 100vh;
  #|         margin: 0;
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|       }
  #|       button {
  #|         font-size: 1.5rem;
  #|         cursor: pointer;
  #|         padding: 10px 20px;
  #|         background-color: #007bff;
  #|         color: white;
  #|         border: none;
  #|         border-radius: 5px;
  #|       }
  #|       pre {
  #|         max-width: 40rem;
  #|         margin-top: 1rem;
  #|         padding: 1rem;
  #|         border-radius: 8px;
  #|         background: #f3f5f7;
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
  #|     <button onclick="press('I was pressed!', 123, new Date().toISOString()).then(log).catch(logError);">
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
  webview.set_title("Moonbit Webview Example")
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
