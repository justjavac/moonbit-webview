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
  ..run()
}
