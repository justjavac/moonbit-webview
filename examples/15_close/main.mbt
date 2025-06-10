///|
/// Defines the HTML template for the close example.
/// 
/// This HTML includes a button that, when pressed, closes the webview.
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
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  ..run()
}
