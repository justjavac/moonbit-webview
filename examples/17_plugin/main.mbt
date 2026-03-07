///|
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       body {
  #|         margin: 0;
  #|         min-height: 100vh;
  #|         display: grid;
  #|         place-items: center;
  #|         background:
  #|           radial-gradient(circle at top, #f7f1d9 0%, transparent 42%),
  #|           linear-gradient(160deg, #dce9f4 0%, #f6efe4 100%);
  #|         color: #14212b;
  #|         font-family: "Avenir Next", "Gill Sans", sans-serif;
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
  #|       <h1>Plugin Host</h1>
  #|       <p>A MoonBit plugin module installs a namespaced JS API and event stream on <code>window.MoonBitPlugins</code>, and each call returns a structured <code>CommandResponse</code>.</p>
  #|       <button id="run">Call math.sum</button>
  #|       <pre id="output">Click the button.</pre>
  #|     </main>
  #|     <script>
  #|       const output = document.getElementById("output");
  #|       let lastEvent = null;
  #|       window.MoonBitPlugins.math["@@onEvent"]("computed", (event) => {
  #|         lastEvent = event;
  #|         output.textContent =
  #|           "Plugin event:\n" + JSON.stringify(event, null, 2);
  #|       });
  #|       document.getElementById("run").addEventListener("click", () => {
  #|         window.MoonBitPlugins.math
  #|           .sum({ left: 20, right: 22 })
  #|           .then((response) => {
  #|             if (response.status === "ok") {
  #|               output.textContent =
  #|                 "Plugin payload:\n" + JSON.stringify(response.payload, null, 2) +
  #|                 "\n\nLast event:\n" + JSON.stringify(lastEvent, null, 2);
  #|               return;
  #|             }
  #|             output.textContent =
  #|               "Plugin error:\n" + JSON.stringify(response, null, 2);
  #|           })
  #|           .catch((error) => {
  #|             output.textContent = "Transport error:\n" + String(error);
  #|           });
  #|       });
  #|     </script>
  #|   </body>
  #| </html>

///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  let plugins = @webview.PluginHost::new(webview)
  plugins.install(plugin())
  webview.set_title("MoonBit Plugin Host")
  webview.set_size(900, 640, @webview.SizeHint::None)
  webview.set_html(html)
  plugins.run()
}
