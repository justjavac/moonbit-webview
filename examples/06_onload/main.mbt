///|
/// Defines an HTML template that displays "Hello, Moonbit!" in the center of the
/// window.
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       body {
  #|         display: flex;
  #|         align-items: center;
  #|         justify-content: center;
  #|         height: 100vh;
  #|         margin: 0;
  #|         font-size: 3.75rem;
  #|         font-family: "Segoe UI", "Roboto", "Helvetica Neue", sans-serif;
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <script>
  #|       addEventListener("DOMContentLoaded", () => {
  #|         document.body.innerHTML = "Hello, Moonbit!";
  #|       });
  #|     </script>
  #|   </body>
  #| </html>

///|
/// Creates a window with "Hello, Moonbit!" displayed in the center using a
/// customized HTML template.
/// 
/// The text is rendered after the DOM content is loaded using JavaScript.
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  ..run()
}
