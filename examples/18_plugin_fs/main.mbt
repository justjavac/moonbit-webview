///|
let html =
  #| <html>
  #|   <head>
  #|     <style>
  #|       body {
  #|         margin: 0;
  #|         min-height: 100vh;
  #|         background:
  #|           radial-gradient(circle at top left, #f4e6bb 0%, transparent 35%),
  #|           linear-gradient(160deg, #dce8f4 0%, #f6efe4 100%);
  #|         color: #15222c;
  #|         font-family: "Avenir Next", "Gill Sans", sans-serif;
  #|       }
  #|       .shell {
  #|         width: min(72rem, calc(100vw - 2rem));
  #|         margin: 1rem auto;
  #|         padding: 1.25rem;
  #|         border-radius: 26px;
  #|         background: rgba(255, 255, 255, 0.9);
  #|         border: 1px solid rgba(255, 255, 255, 0.7);
  #|         box-shadow: 0 24px 80px rgba(21, 34, 44, 0.16);
  #|       }
  #|       h1,
  #|       h2,
  #|       p {
  #|         margin: 0;
  #|       }
  #|       .hero {
  #|         display: grid;
  #|         gap: 0.75rem;
  #|         margin-bottom: 1rem;
  #|       }
  #|       .hero p {
  #|         color: #61737c;
  #|         max-width: 48rem;
  #|       }
  #|       .hero code {
  #|         padding: 0.15rem 0.4rem;
  #|         border-radius: 999px;
  #|         background: #dceef0;
  #|       }
  #|       .layout {
  #|         display: grid;
  #|         grid-template-columns: minmax(0, 1.45fr) minmax(18rem, 0.95fr);
  #|         gap: 1rem;
  #|       }
  #|       .column {
  #|         display: grid;
  #|         gap: 1rem;
  #|       }
  #|       .panel {
  #|         padding: 1rem;
  #|         border-radius: 20px;
  #|         background: #eef3f6;
  #|         border: 1px solid rgba(21, 34, 44, 0.12);
  #|       }
  #|       .panel-head {
  #|         display: flex;
  #|         align-items: center;
  #|         justify-content: space-between;
  #|         gap: 0.75rem;
  #|         margin-bottom: 0.9rem;
  #|       }
  #|       .muted {
  #|         color: #61737c;
  #|         font-size: 0.95rem;
  #|       }
  #|       .form {
  #|         display: grid;
  #|         gap: 0.85rem;
  #|       }
  #|       label {
  #|         display: grid;
  #|         gap: 0.35rem;
  #|         font-size: 0.95rem;
  #|         font-weight: 600;
  #|       }
  #|       input,
  #|       textarea {
  #|         width: 100%;
  #|         box-sizing: border-box;
  #|         border: 1px solid rgba(21, 34, 44, 0.12);
  #|         border-radius: 14px;
  #|         background: rgba(255, 255, 255, 0.92);
  #|         color: #15222c;
  #|         font: inherit;
  #|         padding: 0.8rem 0.95rem;
  #|       }
  #|       textarea {
  #|         min-height: 16rem;
  #|         resize: vertical;
  #|         line-height: 1.45;
  #|       }
  #|       .actions {
  #|         display: grid;
  #|         grid-template-columns: repeat(2, minmax(0, 1fr));
  #|         gap: 0.75rem;
  #|       }
  #|       button {
  #|         border: 0;
  #|         border-radius: 999px;
  #|         padding: 0.82rem 1rem;
  #|         background: #15222c;
  #|         color: white;
  #|         font: inherit;
  #|         font-weight: 600;
  #|         cursor: pointer;
  #|       }
  #|       button.secondary {
  #|         background: #0e6c75;
  #|       }
  #|       button.ghost {
  #|         background: white;
  #|         color: #15222c;
  #|         border: 1px solid rgba(21, 34, 44, 0.12);
  #|       }
  #|       button.danger {
  #|         background: #9a3d32;
  #|       }
  #|       button:disabled {
  #|         opacity: 0.6;
  #|         cursor: progress;
  #|       }
  #|       .notice {
  #|         border-radius: 16px;
  #|         padding: 0.8rem 0.95rem;
  #|         background: white;
  #|         border: 1px solid rgba(21, 34, 44, 0.12);
  #|         line-height: 1.45;
  #|       }
  #|       .notice.ok {
  #|         background: #dceff1;
  #|       }
  #|       .notice.error {
  #|         background: #f7dfdb;
  #|       }
  #|       .chips {
  #|         display: flex;
  #|         flex-wrap: wrap;
  #|         gap: 0.55rem;
  #|         margin-top: 0.75rem;
  #|       }
  #|       .chip {
  #|         border-radius: 999px;
  #|         padding: 0.45rem 0.7rem;
  #|         background: white;
  #|         border: 1px solid rgba(21, 34, 44, 0.12);
  #|         font-size: 0.92rem;
  #|       }
  #|       .chip strong {
  #|         margin-right: 0.35rem;
  #|         color: #61737c;
  #|         text-transform: uppercase;
  #|         font-size: 0.78rem;
  #|       }
  #|       .meta {
  #|         display: grid;
  #|         grid-template-columns: repeat(2, minmax(0, 1fr));
  #|         gap: 0.6rem;
  #|         margin-top: 0.75rem;
  #|       }
  #|       .meta-card {
  #|         border-radius: 14px;
  #|         padding: 0.75rem 0.85rem;
  #|         background: white;
  #|         border: 1px solid rgba(21, 34, 44, 0.12);
  #|       }
  #|       .meta-card strong {
  #|         display: block;
  #|         margin-bottom: 0.2rem;
  #|         color: #61737c;
  #|         font-size: 0.78rem;
  #|         text-transform: uppercase;
  #|       }
  #|       .list {
  #|         margin: 0;
  #|         padding: 0;
  #|         list-style: none;
  #|         display: grid;
  #|         gap: 0.45rem;
  #|         max-height: 15rem;
  #|         overflow: auto;
  #|       }
  #|       .list li {
  #|         border-radius: 14px;
  #|         background: white;
  #|         border: 1px solid rgba(21, 34, 44, 0.12);
  #|         padding: 0.7rem 0.8rem;
  #|         font-family: "SF Mono", "Menlo", monospace;
  #|         font-size: 0.88rem;
  #|       }
  #|       .empty {
  #|         color: #61737c;
  #|         font-style: italic;
  #|       }
  #|       @media (max-width: 860px) {
  #|         .layout {
  #|           grid-template-columns: 1fr;
  #|         }
  #|         .actions,
  #|         .meta {
  #|           grid-template-columns: 1fr;
  #|         }
  #|       }
  #|     </style>
  #|   </head>
  #|   <body>
  #|     <div class="shell">
  #|       <div class="hero">
  #|         <h1>Filesystem Plugin Demo</h1>
  #|         <p>Use <code>window.MoonBitPlugins.fs</code> like a small file workbench: edit text, save it, load it back, inspect file metadata, browse the parent directory, and watch native plugin activity.</p>
  #|       </div>
  #|       <div class="layout">
  #|         <div class="column">
  #|           <div class="panel">
  #|             <div class="panel-head">
  #|               <div>
  #|                 <h2>Editor</h2>
  #|                 <p class="muted">Work with a UTF-8 text file on disk.</p>
  #|               </div>
  #|               <button id="seed" class="ghost">Insert Sample</button>
  #|             </div>
  #|             <div class="form">
  #|               <label>
  #|                 File path
  #|                 <input id="path" value="/tmp/moonbit-webview-plugin-demo.txt" />
  #|               </label>
  #|               <label>
  #|                 Content
  #|                 <textarea id="content">Hello from the fs plugin.
  #| 
  #| This demo writes text through MoonBit, reads it back, and shows plugin activity emitted from the native side.</textarea>
  #|               </label>
  #|               <div class="actions">
  #|                 <button id="save">Save File</button>
  #|                 <button id="load" class="secondary">Load File</button>
  #|                 <button id="inspect" class="ghost">Inspect File</button>
  #|                 <button id="delete" class="danger">Delete File</button>
  #|               </div>
  #|             </div>
  #|           </div>
  #|           <div class="panel">
  #|             <div class="panel-head">
  #|               <div>
  #|                 <h2>Directory</h2>
  #|                 <p class="muted">List entries next to the current file path.</p>
  #|               </div>
  #|               <button id="listDir" class="ghost">Refresh List</button>
  #|             </div>
  #|             <ul id="dirList" class="list">
  #|               <li class="empty">No directory listing yet.</li>
  #|             </ul>
  #|           </div>
  #|         </div>
  #|         <div class="column">
  #|           <div class="panel">
  #|             <div class="panel-head">
  #|               <div>
  #|                 <h2>File State</h2>
  #|                 <p class="muted">Latest metadata and command status.</p>
  #|               </div>
  #|             </div>
  #|             <div id="notice" class="notice">Ready.</div>
  #|             <div class="chips">
  #|               <div class="chip"><strong>Exists</strong><span id="existsChip">Unknown</span></div>
  #|               <div class="chip"><strong>Size</strong><span id="sizeChip">-</span></div>
  #|               <div class="chip"><strong>Position</strong><span id="positionChip">-</span></div>
  #|               <div class="chip"><strong>EOF</strong><span id="eofChip">-</span></div>
  #|             </div>
  #|             <div class="meta">
  #|               <div class="meta-card"><strong>Path</strong><span id="metaPath">-</span></div>
  #|               <div class="meta-card"><strong>Type</strong><span id="metaType">-</span></div>
  #|               <div class="meta-card"><strong>Last Read</strong><span id="metaRead">-</span></div>
  #|               <div class="meta-card"><strong>Last Write</strong><span id="metaWrite">-</span></div>
  #|             </div>
  #|           </div>
  #|           <div class="panel">
  #|             <div class="panel-head">
  #|               <div>
  #|                 <h2>Plugin Activity</h2>
  #|                 <p class="muted">Recent events emitted by the native fs plugin.</p>
  #|               </div>
  #|             </div>
  #|             <ul id="eventLog" class="list">
  #|               <li class="empty">No plugin events yet.</li>
  #|             </ul>
  #|           </div>
  #|         </div>
  #|       </div>
  #|     </div>
  #|     <script>
  #|       var pathInput = document.getElementById("path");
  #|       var contentInput = document.getElementById("content");
  #|       var dirList = document.getElementById("dirList");
  #|       var eventLog = document.getElementById("eventLog");
  #|       var notice = document.getElementById("notice");
  #|       var existsChip = document.getElementById("existsChip");
  #|       var sizeChip = document.getElementById("sizeChip");
  #|       var positionChip = document.getElementById("positionChip");
  #|       var eofChip = document.getElementById("eofChip");
  #|       var metaPath = document.getElementById("metaPath");
  #|       var metaType = document.getElementById("metaType");
  #|       var metaRead = document.getElementById("metaRead");
  #|       var metaWrite = document.getElementById("metaWrite");
  #|       var buttons = Array.prototype.slice.call(document.querySelectorAll("button"));
  #|       var fs = window.MoonBitPlugins.fs;
  #|       var lastReadAt = "-";
  #|       var lastWriteAt = "-";
  #|       var activityLog = [];
  #| 
  #|       function expectOk(response) {
  #|         if (response.status === "ok") {
  #|           return response.payload;
  #|         }
  #|         throw new Error(response.error || "Plugin command failed");
  #|       }
  #| 
  #|       function parentDir(path) {
  #|         var separator = path.lastIndexOf("/");
  #|         return separator <= 0 ? "/" : path.slice(0, separator);
  #|       }
  #| 
  #|       function nowLabel() {
  #|         return new Date().toLocaleTimeString([], {
  #|           hour: "2-digit",
  #|           minute: "2-digit",
  #|           second: "2-digit",
  #|         });
  #|       }
  #| 
  #|       function setBusy(busy) {
  #|         buttons.forEach(function(button) {
  #|           button.disabled = busy;
  #|         });
  #|       }
  #| 
  #|       function setNotice(message, kind) {
  #|         notice.textContent = message;
  #|         notice.className = "notice " + (kind || "ok");
  #|       }
  #| 
  #|       function renderStat(stat) {
  #|         existsChip.textContent = stat ? (stat.exists ? "Yes" : "No") : "Unknown";
  #|         sizeChip.textContent = stat ? stat.size + " bytes" : "-";
  #|         positionChip.textContent = stat ? String(stat.position) : "-";
  #|         eofChip.textContent = stat ? (stat.eof ? "Yes" : "No") : "-";
  #|         metaPath.textContent = stat && stat.path ? stat.path : (pathInput.value.trim() || "-");
  #|         metaType.textContent = !stat
  #|           ? "-"
  #|           : stat.is_dir
  #|             ? "Directory"
  #|             : stat.is_file
  #|               ? "File"
  #|               : "Missing";
  #|         metaRead.textContent = lastReadAt;
  #|         metaWrite.textContent = lastWriteAt;
  #|       }
  #| 
  #|       function renderDirEntries(entries) {
  #|         dirList.innerHTML = "";
  #|         if (!entries.length) {
  #|           var emptyItem = document.createElement("li");
  #|           emptyItem.className = "empty";
  #|           emptyItem.textContent = "The directory is empty.";
  #|           dirList.appendChild(emptyItem);
  #|           return;
  #|         }
  #|         entries.forEach(function(entry) {
  #|           var item = document.createElement("li");
  #|           item.textContent = entry;
  #|           dirList.appendChild(item);
  #|         });
  #|       }
  #| 
  #|       function renderActivityLog() {
  #|         eventLog.innerHTML = "";
  #|         if (!activityLog.length) {
  #|           var emptyItem = document.createElement("li");
  #|           emptyItem.className = "empty";
  #|           emptyItem.textContent = "No plugin events yet.";
  #|           eventLog.appendChild(emptyItem);
  #|           return;
  #|         }
  #|         activityLog.forEach(function(entry) {
  #|           var item = document.createElement("li");
  #|           item.textContent = entry.operation + entry.detail;
  #|           var line = document.createElement("div");
  #|           line.className = "muted";
  #|           line.textContent = entry.time;
  #|           item.appendChild(line);
  #|           eventLog.appendChild(item);
  #|         });
  #|       }
  #| 
  #|       function rememberActivity(event) {
  #|         var bits = [];
  #|         if (event.payload.path) {
  #|           bits.push(event.payload.path);
  #|         }
  #|         if (event.payload.handle != null) {
  #|           bits.push("handle " + event.payload.handle);
  #|         }
  #|         if (event.payload.bytes != null) {
  #|           bits.push(event.payload.bytes + " bytes");
  #|         }
  #|         activityLog.unshift({
  #|           operation: event.payload.operation,
  #|           detail: bits.length ? " - " + bits.join(" - ") : "",
  #|           time: nowLabel(),
  #|         });
  #|         activityLog = activityLog.slice(0, 8);
  #|         renderActivityLog();
  #|       }
  #| 
  #|       function withOpenFile(path, mode, callback) {
  #|         return fs.open({ path: path, mode: mode }).then(function(response) {
  #|           var opened = expectOk(response);
  #|           var handle = opened.handle;
  #|           return callback(handle).then(
  #|             function(result) {
  #|               return fs.close({ handle: handle }).then(function() {
  #|                 return result;
  #|               });
  #|             },
  #|             function(error) {
  #|               return fs.close({ handle: handle }).then(function() {
  #|                 throw error;
  #|               });
  #|             },
  #|           );
  #|         });
  #|       }
  #| 
  #|       function saveFile(path, content) {
  #|         return withOpenFile(path, "w+b", function(handle) {
  #|           return fs.write({ handle: handle, content: content })
  #|             .then(function(response) {
  #|               var written = expectOk(response);
  #|               return fs.flush({ handle: handle }).then(function() {
  #|                 return written;
  #|               });
  #|             })
  #|             .then(function(written) {
  #|               return fs.seek({ handle: handle, offset: 0, whence: "set" }).then(function() {
  #|                 return written;
  #|               });
  #|             })
  #|             .then(function(written) {
  #|               return fs.fstat({ handle: handle }).then(function(response) {
  #|                 return {
  #|                   written: written,
  #|                   stat: expectOk(response),
  #|                 };
  #|               });
  #|             });
  #|         });
  #|       }
  #| 
  #|       function loadFile(path) {
  #|         return withOpenFile(path, "rb", function(handle) {
  #|           return fs.fstat({ handle: handle }).then(function(response) {
  #|             var stat = expectOk(response);
  #|             return fs.read({ handle: handle, size: Math.max(stat.size, 1) + 1 }).then(function(response) {
  #|               return {
  #|                 stat: stat,
  #|                 read: expectOk(response),
  #|               };
  #|             });
  #|           });
  #|         });
  #|       }
  #| 
  #|       function inspectFile(path) {
  #|         return fs.exists({ path: path }).then(function(response) {
  #|           var exists = expectOk(response);
  #|           if (!exists.exists) {
  #|             return {
  #|               path: path,
  #|               size: 0,
  #|               position: 0,
  #|               eof: false,
  #|               exists: false,
  #|               is_file: false,
  #|               is_dir: false,
  #|             };
  #|           }
  #|           return withOpenFile(path, "rb", function(handle) {
  #|             return fs.fstat({ handle: handle }).then(function(response) {
  #|               return expectOk(response);
  #|             });
  #|           });
  #|         });
  #|       }
  #| 
  #|       fs["@@onEvent"]("activity", function(event) {
  #|         rememberActivity(event);
  #|       });
  #| 
  #|       document.getElementById("seed").addEventListener("click", function() {
  #|         contentInput.value =
  #|           "MoonBit fs plugin demo\n\n" +
  #|           "- Save writes the editor content to disk\n" +
  #|           "- Load reads the file back into the editor\n" +
  #|           "- Inspect shows fstat metadata\n" +
  #|           "- Refresh List shows sibling files\n";
  #|         setNotice("Sample content inserted into the editor.");
  #|       });
  #| 
  #|       document.getElementById("save").addEventListener("click", function() {
  #|         var path = pathInput.value.trim();
  #|         if (!path) {
  #|           setNotice("Enter a file path before saving.", "error");
  #|           return;
  #|         }
  #|         setBusy(true);
  #|         saveFile(path, contentInput.value).then(
  #|           function(result) {
  #|             lastWriteAt = nowLabel();
  #|             renderStat(result.stat);
  #|             setNotice("Saved " + result.written.bytes_written + " bytes to " + path + ".");
  #|             setBusy(false);
  #|           },
  #|           function(error) {
  #|             setNotice("Save failed: " + String(error), "error");
  #|             setBusy(false);
  #|           },
  #|         );
  #|       });
  #| 
  #|       document.getElementById("load").addEventListener("click", function() {
  #|         var path = pathInput.value.trim();
  #|         if (!path) {
  #|           setNotice("Enter a file path before loading.", "error");
  #|           return;
  #|         }
  #|         setBusy(true);
  #|         loadFile(path).then(
  #|           function(result) {
  #|             contentInput.value = result.read.content;
  #|             lastReadAt = nowLabel();
  #|             renderStat(result.stat);
  #|             setNotice("Loaded " + result.read.bytes_read + " bytes from " + path + ".");
  #|             setBusy(false);
  #|           },
  #|           function(error) {
  #|             setNotice("Load failed: " + String(error), "error");
  #|             setBusy(false);
  #|           },
  #|         );
  #|       });
  #| 
  #|       document.getElementById("inspect").addEventListener("click", function() {
  #|         var path = pathInput.value.trim();
  #|         if (!path) {
  #|           setNotice("Enter a file path before inspecting.", "error");
  #|           return;
  #|         }
  #|         setBusy(true);
  #|         inspectFile(path).then(
  #|           function(stat) {
  #|             renderStat(stat);
  #|             setNotice(stat.exists ? "Inspected " + path + "." : path + " does not exist yet.", stat.exists ? "ok" : "error");
  #|             setBusy(false);
  #|           },
  #|           function(error) {
  #|             setNotice("Inspect failed: " + String(error), "error");
  #|             setBusy(false);
  #|           },
  #|         );
  #|       });
  #| 
  #|       document.getElementById("listDir").addEventListener("click", function() {
  #|         var path = pathInput.value.trim();
  #|         setBusy(true);
  #|         fs.readDir({ path: parentDir(path) }).then(
  #|           function(response) {
  #|             var entries = expectOk(response);
  #|             renderDirEntries(entries.entries);
  #|             setNotice("Listed " + entries.entries.length + " entries in " + parentDir(path) + ".");
  #|             setBusy(false);
  #|           },
  #|           function(error) {
  #|             setNotice("Directory listing failed: " + String(error), "error");
  #|             setBusy(false);
  #|           },
  #|         );
  #|       });
  #| 
  #|       document.getElementById("delete").addEventListener("click", function() {
  #|         var path = pathInput.value.trim();
  #|         if (!path) {
  #|           setNotice("Enter a file path before deleting.", "error");
  #|           return;
  #|         }
  #|         setBusy(true);
  #|         fs.removeFile({ path: path }).then(
  #|           function(response) {
  #|             var removed = expectOk(response);
  #|             renderStat({
  #|               path: path,
  #|               size: 0,
  #|               position: 0,
  #|               eof: false,
  #|               exists: false,
  #|               is_file: false,
  #|               is_dir: false,
  #|             });
  #|             setNotice(
  #|               removed.removed ? "Deleted " + path + "." : path + " was already absent.",
  #|               removed.removed ? "ok" : "error",
  #|             );
  #|             setBusy(false);
  #|           },
  #|           function(error) {
  #|             setNotice("Delete failed: " + String(error), "error");
  #|             setBusy(false);
  #|           },
  #|         );
  #|       });
  #| 
  #|       renderStat(null);
  #|       renderActivityLog();
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
