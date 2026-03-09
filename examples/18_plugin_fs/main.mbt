///|
let resource : String =
  #| <html>
  #|   <head>
  #|     <style>
  #|       body {
  #|         margin: 0;
  #|         min-height: 100vh;
  #|         display: grid;
  #|         place-items: center;
  #|         background: linear-gradient(135deg, #f4f0e8 0%, #dbe7f3 100%);
  #|         color: #14212b;
  #|         font-family: "Iowan Old Style", "Palatino Linotype", serif;
  #|       }
  #|       main {
  #|         width: min(34rem, calc(100vw - 3rem));
  #|         padding: 2rem;
  #|         border-radius: 22px;
  #|         background: rgba(255, 255, 255, 0.84);
  #|         box-shadow: 0 24px 70px rgba(20, 33, 43, 0.14);
  #|       }
  #|       button {
  #|         border: 0;
  #|         border-radius: 999px;
  #|         padding: 0.85rem 1.2rem;
  #|         background: #14212b;
  #|         color: white;
  #|         font: inherit;
  #|         cursor: pointer;
  #|       }
  #|       input { width: 100%; padding: 0.5rem 0.75rem; border-radius: 6px; border:1px solid #ccc; }
  #|       pre {
  #|         margin-top: 1rem;
  #|         padding: 1rem;
  #|         border-radius: 14px;
  #|         background: #eef3f7;
  #|         white-space: pre-wrap;
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <main>
  #|       <h1>MoonBit Plugin FS</h1>
  #|       <p>Use the embedded plugin to read files from a tiny in-memory map.</p>
  #|       <input id="path" placeholder="/README.md" />
  #|       <button id="read">Read File</button>
  #|       <pre id="output">Awaiting input…</pre>
  #|     </main>
  #|     <script>
  #|       const output = document.getElementById("output");
  #|       document.getElementById("read").addEventListener("click", () => {
  #|         const path = document.getElementById("path").value || "/README.md";
  #|         window.MoonBitPlugins.fs
  #|           .read({ path: path })
  #|           .then((resp) => {
  #|             output.textContent = "Content:\n" + resp.content;
  #|           })
  #|           .catch((err) => {
  #|             output.textContent = "Error:\n" + String(err);
  #|           });
  #|       });
  #|     </script>
  #|   </body>
  #| </html>
  #|
// resource string embedding complete UI HTML
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.install_plugin(plugin())
  webview.set_title("MoonBit Plugin FS")
  webview.set_size(900, 640, @webview.SizeHint::None)
  webview.set_html(resource)
  webview.run()
}
