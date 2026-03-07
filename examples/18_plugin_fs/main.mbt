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
  #|       <h1>Filesystem Plugin</h1>
  #|       <p>The <code>fs</code> plugin exposes handle-based file operations through <code>window.MoonBitPlugins.fs</code>.</p>
  #|       <label>
  #|         File path
  #|         <input id="path" value="/tmp/moonbit-webview-plugin-demo.txt" />
  #|       </label>
  #|       <label>
  #|         Content
  #|         <textarea id="content">Hello from the fs plugin.</textarea>
  #|       </label>
  #|       <div class="actions">
  #|         <button id="roundTrip">Open / write / fstat / read / close</button>
  #|         <button id="listDir">List parent directory</button>
  #|         <button id="remove">Remove file</button>
  #|       </div>
  #|       <pre id="output">Run an fs operation.</pre>
  #|     </main>
  #|     <script>
  #|       const output = document.getElementById("output");
  #|       const pathInput = document.getElementById("path");
  #|       const contentInput = document.getElementById("content");
  #|       let lastEvent = null;
  #|       const fs = window.MoonBitPlugins.fs;
  #|       const expectOk = (response) => {
  #|         if (response.status === "ok") {
  #|           return response.payload;
  #|         }
  #|         throw new Error(response.error || "Plugin command failed");
  #|       };
  #|       const parentDir = (path) => {
  #|         const separator = path.lastIndexOf("/");
  #|         return separator <= 0 ? "/" : path.slice(0, separator);
  #|       };
  #|       fs["@@onEvent"]("activity", (event) => {
  #|         lastEvent = event;
  #|       });
  #|       document.getElementById("roundTrip").addEventListener("click", async () => {
  #|         const path = pathInput.value.trim();
  #|         const content = contentInput.value;
  #|         try {
  #|           const opened = expectOk(await fs.open({ path, mode: "w+b" }));
  #|           const handle = opened.handle;
  #|           const written = expectOk(await fs.write({ handle, content }));
  #|           expectOk(await fs.flush({ handle }));
  #|           const rewound = expectOk(await fs.seek({
  #|             handle,
  #|             offset: 0,
  #|             whence: "set",
  #|           }));
  #|           const stat = expectOk(await fs.fstat({ handle }));
  #|           const read = expectOk(await fs.read({ handle, size: 4096 }));
  #|           const closed = expectOk(await fs.close({ handle }));
  #|           const exists = expectOk(await fs.exists({ path }));
  #|           output.textContent =
  #|             "Round trip result:\n" +
  #|             JSON.stringify(
  #|               {
  #|                 opened,
  #|                 written,
  #|                 rewound,
  #|                 stat,
  #|                 read,
  #|                 closed,
  #|                 exists,
  #|                 lastEvent,
  #|               },
  #|               null,
  #|               2,
  #|             );
  #|         } catch (error) {
  #|           output.textContent = "FS error:\n" + String(error);
  #|         }
  #|       });
  #|       document.getElementById("listDir").addEventListener("click", async () => {
  #|         const path = pathInput.value.trim();
  #|         try {
  #|           const entries = expectOk(await fs.readDir({ path: parentDir(path) }));
  #|           output.textContent =
  #|             "Directory entries:\n" +
  #|             JSON.stringify({ entries, lastEvent }, null, 2);
  #|         } catch (error) {
  #|           output.textContent = "FS error:\n" + String(error);
  #|         }
  #|       });
  #|       document.getElementById("remove").addEventListener("click", async () => {
  #|         const path = pathInput.value.trim();
  #|         try {
  #|           const removed = expectOk(await fs.removeFile({ path }));
  #|           output.textContent =
  #|             "Remove result:\n" +
  #|             JSON.stringify({ removed, lastEvent }, null, 2);
  #|         } catch (error) {
  #|           output.textContent = "FS error:\n" + String(error);
  #|         }
  #|       });
  #|     </script>
  #|   </body>
  #| </html>

///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.install_plugin(@fs.plugin())
  webview.set_title("MoonBit Filesystem Plugin")
  webview.set_size(960, 720, @webview.SizeHint::None)
  webview.set_html(html)
  webview.run()
}
