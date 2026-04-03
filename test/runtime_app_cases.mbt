///|
test "__MoonBit__ core ops expose extension APIs into JavaScript" {
  let expected_report = OpsRuntimeReport::{
    direct: MultiplyReply::{ total: 42 },
    extension: MultiplyReply::{ total: 42 },
    event_count: 2,
  }
  let mut seen_report : OpsRuntimeReport? = None
  let mut js_error : String? = None
  let webview = @webview.Webview::new()
  @runtime.install_extension(webview, 
    @runtime.Extension::new("math", fn(extension) {
      extension.op("multiply", fn(payload : MultiplyPayload) {
        let reply = MultiplyReply::{ total: payload.left * payload.right }
        extension.emit("computed", ExtensionNotice::{
          message: "MoonBit computed " + reply.total.to_string(),
        })
        reply
      })
    }),
  )
  webview.bind("reportOpsFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some("Failed to decode ops failure payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportOpsRuntime", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let report_result : Result[OpsRuntimeReport, String] = decode_single_argument(
      req,
    )
    match report_result {
      Ok(report) => seen_report = Some(report)
      Err(message) =>
        js_error = Some("Failed to decode ops runtime report: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.set_html(
    (
      #| <html>
      #|   <body>
      #|     <script>
      #|       const reportFailure = (message) =>
      #|         window.reportOpsFailure(message).catch(() => {});
      #|       const waitFor = (predicate, onReady, label, attempts = 0) => {
      #|         if (predicate()) {
      #|           onReady();
      #|           return;
      #|         }
      #|         if (attempts >= 50) {
      #|           void reportFailure(label + " timeout");
      #|           return;
      #|         }
      #|         window.setTimeout(() => {
      #|           waitFor(predicate, onReady, label, attempts + 1);
      #|         }, 20);
      #|       };
      #|       window.addEventListener("error", (event) => {
      #|         void reportFailure("window error: " + String(event.message));
      #|       });
      #|       window.addEventListener("unhandledrejection", (event) => {
      #|         void reportFailure("unhandled rejection: " + String(event.reason));
      #|       });
      #|       window.addEventListener("load", () => {
      #|         waitFor(
      #|           () => {
      #|             const moonbit = window.__MoonBit__;
      #|             return !!moonbit && !!moonbit.math && !!moonbit.core?.ops;
      #|           },
      #|           () => {
      #|             const moonbit = window.__MoonBit__;
      #|             let eventCount = 0;
      #|             let results = null;
      #|             const timeoutId = window.setTimeout(() => {
      #|               void reportFailure("ops report timeout");
      #|             }, 1000);
      #|             const maybeFinish = () => {
      #|               if (!results || eventCount !== 2) {
      #|                 return;
      #|               }
      #|               window.reportOpsRuntime({
      #|                 direct: results.direct,
      #|                 extension: results.extension,
      #|                 event_count: eventCount,
      #|               })
      #|                 .then(() => {
      #|                   window.clearTimeout(timeoutId);
      #|                 })
      #|                 .catch((error) => {
      #|                   void reportFailure("ops report transport error: " + String(error));
      #|                 });
      #|             };
      #|             moonbit.events.on("math.computed", () => {
      #|               eventCount += 1;
      #|               maybeFinish();
      #|             });
      #|             Promise.all([
      #|               moonbit.core.ops.op_math_multiply({ left: 6, right: 7 }),
      #|               moonbit.math.multiply({ left: 6, right: 7 }),
      #|             ])
      #|               .then(([direct, extension]) => {
      #|                 results = { direct, extension };
      #|                 maybeFinish();
      #|               })
      #|               .catch((error) => {
      #|                 void reportFailure("ops transport error: " + String(error));
      #|               });
      #|           },
      #|           "__MoonBit__ runtime",
      #|         );
      #|       });
      #|     </script>
      #|   </body>
      #| </html>,
    ),
  )
  webview.run()
  assert_eq(js_error, None)
  assert_eq(seen_report, Some(expected_report))
}

///|
test "App runtime exposes __MoonBit__ extensions before page load" {
  let expected_response = MultiplyReply::{ total: 42 }
  let expected_event = ExtensionNoticeEvent::{
    extension: "math",
    name: "computed",
    payload: ExtensionNotice::{ message: "MoonBit computed 42" },
  }
  let mut seen_response : MultiplyReply? = None
  let mut seen_event : ExtensionNoticeEvent? = None
  let mut js_error : String? = None
  let config = @runtime.AppConfig::new(
    @runtime.WindowConfig::new("runtime-extension", 800, 600),
    @runtime.AppEntry::Html(
      (
        #| <html>
        #|   <body>
        #|     <script>
      #|       const reportFailure = (message) =>
      #|         window.reportExtensionFailure(message).catch(() => {});
      #|       const waitFor = (predicate, onReady, label, attempts = 0) => {
      #|         if (predicate()) {
      #|           onReady();
      #|           return;
      #|         }
      #|         if (attempts >= 50) {
      #|           void reportFailure(label + " timeout");
      #|           return;
      #|         }
      #|         window.setTimeout(() => {
      #|           waitFor(predicate, onReady, label, attempts + 1);
      #|         }, 20);
      #|       };
      #|       window.addEventListener("error", (event) => {
      #|         void reportFailure("window error: " + String(event.message));
      #|       });
      #|       window.addEventListener("unhandledrejection", (event) => {
      #|         void reportFailure("unhandled rejection: " + String(event.reason));
      #|       });
      #|       window.addEventListener("load", () => {
      #|         waitFor(
      #|           () => {
      #|             const app = window.__MoonBit__;
      #|             return !!app && !!app.math;
      #|           },
      #|           () => {
      #|             const app = window.__MoonBit__;
      #|             app.events.on("math.computed", (event) => {
      #|               void window.reportExtensionEvent(event).catch(() => {});
      #|             });
      #|             app.math
      #|               .multiply({ left: 6, right: 7 })
      #|               .then((response) =>
      #|                 window.reportExtensionResponse(response).catch(() => {}))
      #|               .catch((error) => {
      #|                 void reportFailure("runtime extension transport error: " + String(error));
      #|               });
      #|           },
      #|           "runtime extension",
      #|         );
      #|       });
      #|     </script>
      #|   </body>
        #| </html>,
      ),
    ),
  )
  let app = @runtime.App::new(config)
  let webview = app.webview()
  let finish = fn() {
    if seen_response is Some(_) && seen_event is Some(_) {
      webview.terminate()
    }
  }
  app.install_extension(
    @runtime.Extension::new("math", fn(extension) {
      extension.op("multiply", fn(payload : MultiplyPayload) {
        let reply = MultiplyReply::{ total: payload.left * payload.right }
        extension.emit("computed", ExtensionNotice::{
          message: "MoonBit computed " + reply.total.to_string(),
        })
        reply
      })
    }),
  )
  webview.bind("reportExtensionFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some("Failed to decode runtime extension failure payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportExtensionResponse", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let response_result : Result[MultiplyReply, String] = decode_single_argument(
      req,
    )
    match response_result {
      Ok(response) => {
        seen_response = Some(response)
        finish()
      }
      Err(message) => {
        js_error = Some("Failed to decode runtime extension response payload: " + message)
        webview.terminate()
      }
    }
    webview.response(request_id, 0, "null")
  })
  webview.bind("reportExtensionEvent", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let event_result : Result[ExtensionNoticeEvent, String] = decode_single_argument(
      req,
    )
    match event_result {
      Ok(event) => {
        seen_event = Some(event)
        finish()
      }
      Err(message) => {
        js_error = Some("Failed to decode runtime extension event payload: " + message)
        webview.terminate()
      }
    }
    webview.response(request_id, 0, "null")
  })
  app.run()
  assert_eq(seen_response, Some(expected_response))
  assert_eq(seen_event, Some(expected_event))
  assert_eq(js_error, None)
}

///|
test "__MoonBit__ root exposes consolidated extension runtime surfaces" {
  let expected_report = AppRuntimeHelperReport::{
    via_helper: MultiplyReply::{ total: 42 },
    via_extension: MultiplyReply::{ total: 42 },
    via_core: MultiplyReply::{ total: 42 },
    event_count: 3,
  }
  let mut seen_report : AppRuntimeHelperReport? = None
  let mut js_error : String? = None
  let config = @runtime.AppConfig::new(
    @runtime.WindowConfig::new("runtime-app-helpers", 800, 600),
    @runtime.AppEntry::Html(
      (
        #| <html>
        #|   <body>
        #|     <script>
      #|       const reportFailure = (message) =>
      #|         window.reportAppHelperFailure(message).catch(() => {});
      #|       const waitFor = (predicate, onReady, label, attempts = 0) => {
      #|         if (predicate()) {
      #|           onReady();
      #|           return;
      #|         }
      #|         if (attempts >= 50) {
      #|           void reportFailure(label + " timeout");
      #|           return;
      #|         }
      #|         window.setTimeout(() => {
      #|           waitFor(predicate, onReady, label, attempts + 1);
      #|         }, 20);
      #|       };
      #|       window.addEventListener("error", (event) => {
      #|         void reportFailure("window error: " + String(event.message));
      #|       });
      #|       window.addEventListener("unhandledrejection", (event) => {
      #|         void reportFailure("unhandled rejection: " + String(event.reason));
      #|       });
      #|       window.addEventListener("load", () => {
      #|         waitFor(
      #|           () => {
      #|             const app = window.__MoonBit__;
      #|             return !!app &&
      #|               !!app.extension &&
      #|               !!app.events &&
      #|               !!app.core?.ops &&
      #|               !!app.math;
      #|           },
      #|           () => {
      #|             const app = window.__MoonBit__;
      #|             const math = app.extension("math");
      #|             let eventCount = 0;
      #|             let results = null;
      #|             const maybeFinish = () => {
      #|               if (!results || eventCount !== 3) {
      #|                 return;
      #|               }
      #|               void window.reportAppHelperReport({
      #|                 via_helper: results.viaHelper,
      #|                 via_extension: results.viaExtension,
      #|                 via_core: results.viaCore,
      #|                 event_count: eventCount,
      #|               }).catch(() => {});
      #|             };
      #|             math.on("computed", () => {
      #|               eventCount += 1;
      #|               maybeFinish();
      #|             });
      #|             Promise.all([
      #|               math.invoke("multiply", { left: 6, right: 7 }),
      #|               math.multiply({ left: 6, right: 7 }),
      #|               app.core.ops.op_math_multiply({ left: 6, right: 7 }),
      #|             ])
      #|               .then(([viaHelper, viaExtension, viaCore]) => {
      #|                 results = { viaHelper, viaExtension, viaCore };
      #|                 maybeFinish();
      #|               })
      #|               .catch((error) => {
      #|                 void reportFailure("app helper transport error: " + String(error));
      #|               });
      #|           },
      #|           "__MoonBit__ consolidated helpers",
      #|         );
      #|       });
      #|     </script>
      #|   </body>
      #| </html>,
      ),
    ),
  )
  let app = @runtime.App::new(config)
  let webview = app.webview()
  app.install_extension(
    @runtime.Extension::new("math", fn(extension) {
      extension.op("multiply", fn(payload : MultiplyPayload) {
        let reply = MultiplyReply::{ total: payload.left * payload.right }
        extension.emit("computed", ExtensionNotice::{
          message: "MoonBit computed " + reply.total.to_string(),
        })
        reply
      })
    }),
  )
  webview.bind("reportAppHelperFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some("Failed to decode app helper failure payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportAppHelperReport", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let report_result : Result[AppRuntimeHelperReport, String] = decode_single_argument(
      req,
    )
    match report_result {
      Ok(report) => seen_report = Some(report)
      Err(message) =>
        js_error = Some("Failed to decode app helper report payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  app.run()
  assert_eq(seen_report, Some(expected_report))
  assert_eq(js_error, None)
}

///|
test "App registers additional windows before run" {
  let config = @runtime.AppConfig::new(
    @runtime.WindowConfig::new("runtime-main", 800, 600),
    @runtime.AppEntry::Html("<html>Main</html>"),
    windows=[
      @runtime.AppWindowConfig::new(
        "docs",
        @runtime.WindowConfig::new("Docs", 640, 480),
        @runtime.AppEntry::Html("<html>Docs</html>"),
      ),
    ],
  )
  let app = @runtime.App::new(config)
  assert_eq(app.main_window().id(), "main")
  assert_eq(app.windows().length(), 2)
  match app.window("docs") {
    Some(window) => {
      assert_eq(window.id(), "docs")
      assert_eq(window.config().title, "Docs")
    }
    None => abort("expected docs window")
  }
  app.destroy()
}

///|
test "panic App::install_extension applies to registered windows" {
  let config = @runtime.AppConfig::new(
    @runtime.WindowConfig::new("runtime-main", 800, 600),
    @runtime.AppEntry::Html("<html>Main</html>"),
    windows=[
      @runtime.AppWindowConfig::new(
        "docs",
        @runtime.WindowConfig::new("Docs", 640, 480),
        @runtime.AppEntry::Html("<html>Docs</html>"),
      ),
    ],
  )
  let app = @runtime.App::new(config)
  app.install_extension(@runtime.Extension::new("math", fn(_extension) {  }))
  match app.window("docs") {
    Some(window) =>
      @runtime.install_extension(window.webview(), 
        @runtime.Extension::new("math", fn(_extension) {  }),
      )
    None => abort("expected docs window")
  }
}

