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
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <h1>Hello, Moonbit!</h1>
  #|     <button onclick="press('I was pressed!', 123, new Date()).then(log);">
  #|        Press me!
  #|     </button>
  #|   </body>
  #| </html>

///|
/// Creates and runs a webview window that displays a button.
/// When the button is pressed, it calls the `press` function with a message,
/// a number, and the current date.
fn main {
  let mut counter = 0
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..bind("press", fn(id, req) {
    counter += 1
    println(id)
    println(req)
    println(counter)
  })
  ..set_html(html)
  ..run()
}
